class Revpro::CLI::Commands::Save < Dry::CLI::Command
  attr_reader :lab

  desc "Save progress on a lab"
  argument :lab_path, default: ".", desc: "Path to lab. Default: ."

  def call(lab_path:, **)
    @lab = Revpro::CLI::Codelabs::Revpro.new(path: lab_path)
    @lab.save
  end
end