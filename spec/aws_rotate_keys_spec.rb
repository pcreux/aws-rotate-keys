require "spec_helper"
require "myio"

describe AwsRotateKeys do
  OLD_KEY_ID = "OLDKEY".freeze
  NEW_KEY_ID = "KEY123".freeze
  NEW_SECRET = "SECRET123".freeze

  class IAMDouble
    def create_access_key
      Aws::IAM::Types::CreateAccessKeyResponse.new(
        access_key: Aws::IAM::Types::AccessKey.new(
          access_key_id: NEW_KEY_ID,
          secret_access_key: NEW_SECRET
        )
      )
    end

    def list_access_keys
      Aws::IAM::Types::ListAccessKeysResponse.new(
        access_key_metadata: [
          Aws::IAM::Types::AccessKeyMetadata.new(
            access_key_id: NEW_KEY_ID,
            create_date: Time.new(2017, 2, 1)
          ),
          Aws::IAM::Types::AccessKeyMetadata.new(
            access_key_id: OLD_KEY_ID,
            create_date: Time.new(2017, 1, 1)
          )
        ]
      )
    end

    def delete_access_key(access_key_id:); end
  end

  let(:iam_double) { IAMDouble.new }
  let(:credentials_path) { "./spec/tmp/aws/credentials" }

  def rotate_keys(args = {})
    AwsRotateKeys::CLI.call(
      {
        iam: iam_double,
        credentials_path: credentials_path
      }.merge(args)
    )
  end

  before do
    expect(iam_double).to receive(:delete_access_key).with(access_key_id: OLD_KEY_ID)
  end

  context "when no credentials" do
    before do
      FileUtils.rm_rf("./spec/tmp")
    end

    it "rotates the keys and creates the credentials file" do
      rotate_keys

      credentials_content = File.read(credentials_path)

      expect(credentials_content).to eq "[default]\naws_access_key_id = #{NEW_KEY_ID}\naws_secret_access_key = #{NEW_SECRET}\n"
    end
  end

  context "when credentials already exist" do
    before do
      FileUtils.touch(credentials_path)
    end

    it "rotates keys, backup the old credentials file and create the credentials file" do
      credentials_dir = File.dirname(credentials_path)
      credentials = Dir["#{credentials_dir}/*"]
      rotate_keys
      backups =  Dir["#{credentials_dir}/*"] - credentials
      expect(backups.size).to eq 1

      backup = backups.first
      expect(backup).to match(/credentials.bkp-\d\d\d\d-\d\d-\d\d-\d\d-\d\d-\d\d/)
    end
  end

  describe "friendly message inviting the user to remove AWS env variables" do
    it "displays it when the env variables are set" do
      stdout = MyIO.new

      rotate_keys(env: { "AWS_ACCESS_KEY_ID" => "123" }, stdout: stdout)

      expect(stdout.to_s).to include "AWS_ACCESS_KEY_ID"
    end

    it "does not display it when the env variables are not set" do
      stdout = MyIO.new

      rotate_keys(env: {}, stdout: stdout)

      expect(stdout.to_s).to_not include "AWS_ACCESS_KEY_ID"
    end
  end
end
