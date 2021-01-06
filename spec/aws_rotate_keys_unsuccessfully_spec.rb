require "spec_helper"
require "myio"

describe AwsRotateKeys do
  ACTIVE_KEY_ID = "ACTKEEEY".freeze
  INACTIVE_KEY_ID = "INACTKEY".freeze
  ANOTHER_KEY_ID = "NEWKEEEY".freeze
  ANOTHER_SECRET = "SECRET123".freeze

  class IAMAnotherDouble
    def initialize
      @keys = [
        Aws::IAM::Types::AccessKeyMetadata.new(
          access_key_id: INACTIVE_KEY_ID,
          status: "Inactive",
          create_date: Time.new(2017, 1, 1)
        ),
        Aws::IAM::Types::AccessKeyMetadata.new(
          access_key_id: ACTIVE_KEY_ID,
          status: "Active",
          create_date: Time.new(2017, 2, 1)
        )
      ]
    end

    def create_access_key
      @keys << Aws::IAM::Types::AccessKeyMetadata.new(
        access_key_id: ANOTHER_KEY_ID,
        status: "Active",
        create_date: Time.new(2017, 3, 1)
      )

      Aws::IAM::Types::CreateAccessKeyResponse.new(
        access_key: Aws::IAM::Types::AccessKey.new(
          access_key_id: ANOTHER_KEY_ID,
          secret_access_key: ANOTHER_SECRET
        )
      )
    end

    def list_access_keys
      Aws::IAM::Types::ListAccessKeysResponse.new(
        access_key_metadata: @keys
      )
    end

    def get_account_summary
      Aws::IAM::Types::GetAccountSummaryResponse.new(
        summary_map: {
          "AccessKeysPerUserQuota" => 2
        }
      )
    end

    def delete_access_key(access_key_id:)
      @keys.reject! { |k| k.access_key_id == access_key_id }
    end
  end

  let(:iam_double) { IAMAnotherDouble.new }
  let(:credentials_path) { "./spec/tmp/aws/credentials" }

  def rotate_keys(args = {})
    AwsRotateKeys::CLI.call(
      {
        iam: iam_double,
        credentials_path: credentials_path
      }.merge(args)
    )
  end

  context "when at quota and no override" do
    it "raises an error" do
      stdout = MyIO.new
      expected_err = "You must manually delete a key or use one of the command-line overrides"
      expect { rotate_keys(stdout: stdout) }.to raise_error(RuntimeError, expected_err)
      expect(stdout.to_s).to include "Key set is already at quota limit"
    end
  end

  context "when at quota with override" do
    before do
      expect(iam_double).to receive(:delete_access_key).with(access_key_id: INACTIVE_KEY_ID).and_call_original
      expect(iam_double).to receive(:delete_access_key).with(access_key_id: ACTIVE_KEY_ID).and_call_original
      FileUtils.touch(credentials_path)
    end

    it "deletes both the inactive key and the active key" do
      credentials_dir = File.dirname(credentials_path)
      credentials = Dir["#{credentials_dir}/*"]
      stdout = MyIO.new
      rotate_keys(stdout: stdout, options: { delete_inactive: true })
      expect(stdout.to_s).to include "Key set is already at quota limit"
      expect(stdout.to_s).to include "Deleting oldest inactive access key as requested"
    end
  end

end
