require "spec_helper"

describe SchemaManager::Parser do
  let(:instance) do
    described_class.new
  end

  describe "#parse" do
    subject do
      instance.parse(str)
    end

    let(:str) do
      RSpec.configuration.root.join("spec/fixtures/example1.sql").read
    end

    it "returns a SchemaManager::Schema" do
      should be_a SchemaManager::Schema
    end
  end
end