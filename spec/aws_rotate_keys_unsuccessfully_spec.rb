require "spec_helper"
require "myio"

describe AwsRotateKeys do
  ACTIVE_KEY_ID = "ACTKEEEY".freeze
  INACTIVE_KEY_ID = "INACTKEY".freeze

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

end
