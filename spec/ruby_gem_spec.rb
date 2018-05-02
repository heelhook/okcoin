require 'spec_helper'

describe Okcoin::API do
  subject(:ruby_gem) { Okcoin::API.new }

  describe ".new" do
    it "makes a new instance" do
      expect(ruby_gem).to be_a Okcoin::API
    end
  end
end
