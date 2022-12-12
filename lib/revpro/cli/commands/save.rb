class Revpro::CLI::Commands::Save < Revpro::CLI::Command
  attr_reader :lab

  desc "Save progress on a lab"
  argument :lab_path, default: ".", desc: "Path to lab. Default: ."

  def call(lab_path:, **)
    @lab = Revpro::CLI::Codelabs::RevproMultiple.new(lab_path: lab_path)
    @lab.save_and_commit
    @lab.report_save(lab_path)
  end
end
