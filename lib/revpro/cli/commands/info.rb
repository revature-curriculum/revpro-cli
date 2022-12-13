class Revpro::CLI::Commands::Info < Revpro::CLI::Command
  argument :lab_path, default: ".", desc: "Path to lab. Default: ."

  def call(lab_path: ".", **)
    @code_lab = Revpro::CLI::Codelabs::RevproMultiple.new(lab_path: lab_path)
    @code_lab.info

    # binding.pry
  end
end
