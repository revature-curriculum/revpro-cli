class Revpro::CLI::Commands::Save < Dry::CLI::Command
  desc "Save progress on a lab"

  argument :lab_path, default: ".", desc: "Path to lab. Default: ."

  def call(lab_path:, **)
    binding.pry
  end
end