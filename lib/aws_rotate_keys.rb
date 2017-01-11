require "version"
require "aws-sdk"
require 'fileutils'

module AwsRotateKeys
  def self.call(*args)
    Runner.new(*args).call
  end

  class Runner
    attr_reader :iam, :credentials_path, :stdout, :env

    def initialize(iam: Aws::IAM::Client.new,
                   credentials_path: "#{Dir.home}/.aws/credentials",
                   stdout: $stdout,
                   env: ENV)
      @iam = iam
      @credentials_path = credentials_path
      @stdout = stdout
      @env = env
    end

    def call
      log "Creating access key..."
      new_key = create_access_key

      create_credentials_directory_if_needed

      if credentials_file_exists?
        log "Backing up #{credentials_path} to #{credentials_backup_path}..."
        backup_aws_credentials_file
      end

      log "Writing new access key to #{credentials_path}"
      write_aws_credentials_file(new_key)

      log "Deleting your oldest access key..."
      delete_oldest_access_key

      log "You're all set!"

      if aws_environment_variables?
        log aws_environment_variables_warning_message
      end
    end

    private

    def create_access_key
      create_access_key_response = iam.create_access_key
      create_access_key_response.access_key
    end

    def create_credentials_directory_if_needed
      FileUtils.mkdir_p(credentials_dir)
    end

    def credentials_file_exists?
      File.exist?(credentials_path)
    end

    # ex. ~/aws/credentials.bkp-2017-01-06-16-38-07--0800
    def credentials_backup_path
      credentials_path + ".bkp-#{Time.now.to_s.gsub(/[^\d]/, '-')}"
    end

    def backup_aws_credentials_file
      FileUtils.cp(credentials_path, credentials_backup_path)
    end

    def write_aws_credentials_file(access_key)
      File.open(credentials_path, "w") do |f|
        f.puts "[default]"
        f.puts "aws_access_key_id = #{access_key.access_key_id}"
        f.puts "aws_secret_access_key = #{access_key.secret_access_key}"
      end
    end

    def delete_oldest_access_key
      list_access_keys_response = iam.list_access_keys
      access_keys = list_access_keys_response.access_key_metadata

      oldest_access_key = access_keys.sort_by(&:create_date).first
      iam.delete_access_key(access_key_id: oldest_access_key.access_key_id)
    end

    def credentials_dir
      File.dirname(credentials_path)
    end

    def log(msg)
      stdout.puts msg
    end

    def aws_environment_variables?
      env['AWS_ACCESS_KEY_ID'] || env['AWS_SECRET_ACCESS_KEY']
    end

    def aws_environment_variables_warning_message
      "We've noticed that the environment variables AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY are set.\n" +
      "Please remove them so that aws cli and libraries use #{credentials_path} instead."
    end
  end
end
