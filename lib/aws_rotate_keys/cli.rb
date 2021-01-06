require "aws-sdk"
require "fileutils"

module AwsRotateKeys
  class CLI
    AWS_ENVIRONMENT_VARIABLES = ['AWS_ACCESS_KEY_ID', 'AWS_SECRET_ACCESS_KEY'].freeze

    def self.call(*args)
      new(*args).call
    end

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
      log "Reading key quota..."
      quota = access_key_quota

      log "Reading existing keys..."
      access_keys = aws_access_keys

      if quota <= access_keys.size
        log "Key set is already at quota limit of #{quota}:"
        log_keylist(access_keys)
        raise "You must manually delete a key or use one of the command-line overrides"
        end
      end

      log "Creating access key..."
      new_key = create_access_key

      if File.exist?(credentials_path)
        log "Backing up #{credentials_path} to #{credentials_backup_path}..."
        FileUtils.cp(credentials_path, credentials_backup_path)
      end

      log "Writing new access key to #{credentials_path}"
      write_aws_credentials_file(new_key)

      log "Deleting your oldest access key..."
      delete_oldest_access_key(access_keys)

      log aws_environment_variables_warning_message if aws_environment_variables?

      log "You're all set!"
    end

    private

    def create_access_key
      create_access_key_response = iam.create_access_key
      create_access_key_response.access_key
    end

    # ex. ~/aws/credentials.bkp-2017-01-06-16-38-07--0800
    def credentials_backup_path
      credentials_path + ".bkp-#{Time.now.to_s.gsub(/[^\d]/, '-')}"
    end

    def write_aws_credentials_file(access_key)
      FileUtils.mkdir_p(File.dirname(credentials_path)) # ensure credentials directory exists

      File.open(credentials_path, "w") do |f|
        f.puts "[default]"
        f.puts "aws_access_key_id = #{access_key.access_key_id}"
        f.puts "aws_secret_access_key = #{access_key.secret_access_key}"
      end
    end

    def access_key_quota
      ret = @iam.get_account_summary.summary_map["AccessKeysPerUserQuota"]
    end

    def aws_access_keys
      list_access_keys_response = iam.list_access_keys
      list_access_keys_response.access_key_metadata
    end

    def delete_oldest_access_key(access_key_list)
      oldest_access_key = access_key_list.min_by(&:create_date)
      iam.delete_access_key(access_key_id: oldest_access_key.access_key_id)
    end

    def log_keylist(access_keys)
      access_keys.each do |k|
        log "  #{k['create_date']}     #{k['access_key_id']}     #{k['status']}"
      end
    end

    def log(msg)
      stdout.puts msg
    end

    def aws_environment_variables?
      AWS_ENVIRONMENT_VARIABLES.any? { |v| env.key?(v) }
    end

    def aws_environment_variables_warning_message
      "We've noticed that the environment variables #{AWS_ENVIRONMENT_VARIABLES} are set.\n" +
      "Please remove them so that aws cli and libraries use #{credentials_path} instead."
    end
  end
end
