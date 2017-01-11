require "simplecov"
SimpleCov.start

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "aws_rotate_keys"

RSpec.configure do |config|
  config.before do
    allow(Aws::IAM::Client).to receive(:new) { raise "Please use IAM stub!" }
  end
end
