class Revpro::CLI::Commands::Info < Revpro::CLI::Command
  argument :lab_path, default: ".", desc: "Path to lab. Default: ."

  def call(lab_path: ".", **)
    @code_lab = Revpro::CLI::Codelabs::RevproMultiple.new(lab_path: lab_path)
    puts "Path: #{@code_lab.path}"
    puts "Name: #{@code_lab.lab_name}"
    puts "Source: #{@code_lab.source}"
    puts "git_username: #{@code_lab.git_username}"
    # puts "Branch: #{@code_lab.source}"
    # puts "Remote: #{@code_lab.source}"
    binding.pry
  end
end
