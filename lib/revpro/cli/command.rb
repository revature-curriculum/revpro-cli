require_relative "../cli/utils"

class Revpro::CLI::Command < Dry::CLI::Command
    extend Revpro::CLI::Utils::ClassMethods
end