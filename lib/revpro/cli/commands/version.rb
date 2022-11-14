class Revpro::CLI::Commands::Version < Revpro::CLI::Command
    desc "Print version"

    def call(*)
      puts "1.0.0"
    end
end