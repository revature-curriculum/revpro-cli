# frozen_string_literal: true

RSpec.describe Revpro::CLI do
  it "has a version number" do
    expect(Revpro::CLI::VERSION).not_to be nil
  end
end
