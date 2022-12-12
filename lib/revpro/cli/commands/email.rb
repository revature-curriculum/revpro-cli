class Revpro::CLI::Commands::Email < Revpro::CLI::Command
  desc "Reset your Revpro email"

  def call(*)
    Revpro::CLI::Codelabs::RevproMultiple.email
  end
end
