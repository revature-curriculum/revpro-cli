class Revpro::CLI::Commands::Save < Dry::CLI::Command
  desc "Save a test"

  argument :test, required: true, desc: "Test to save"

  def call(test:, **)
    puts "saved test - test: #{test}"
  end
end