require "spec_helper"

describe AwsRotateKeys do
  class IAMDouble
    def create_access_key
      Aws::IAM::Types::CreateAccessKeyResponse.new(
        access_key: Aws::IAM::Types::AccessKey.new(
          access_key_id: "KEY123",
          secret_access_key: "SECRET123"
        )
      )
    end

    def list_access_keys
      Aws::IAM::Types::ListAccessKeysResponse.new(
        access_key_metadata: [
          Aws::IAM::Types::AccessKeyMetadata.new(
            access_key_id: "KEY123",
            create_date: Time.new(2017, 2, 1)
          ),
          Aws::IAM::Types::AccessKeyMetadata.new(
            access_key_id: "OLDKEY",
            create_date: Time.new(2017, 1, 1)
          )
        ]
      )
    end

    def delete_access_key(access_key_id:)
      raise "Expected to delete access key 'OLDKEY' but was #{access_key_id}" unless access_key_id == "OLDKEY"
    end
  end

  let(:iam_double) { IAMDouble.new }
  let(:credentials_path) { "./spec/tmp/aws/credentials" }

  def rotate_keys
    AwsRotateKeys.call(
      iam: iam_double,
      credentials_path: credentials_path
    )
  end

  before do
    expect(iam_double).to receive(:delete_access_key).with(access_key_id: "OLDKEY")
  end

  context "when no credentials" do
    before do
      FileUtils.rm_rf("./spec/tmp")
    end

    it "rotates the keys and creates the credentials file" do
      rotate_keys

      credentials_content = File.read(credentials_path)

      expect(credentials_content).to eq "[default]\naws_access_key_id = KEY123\naws_secret_access_key = SECRET123\n"
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
end
