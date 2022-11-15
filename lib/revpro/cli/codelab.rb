class Revpro::CLI::Codelab  
  extend Revpro::CLI::Utils::ClassMethods

  attr_accessor :path, :manifest_path
  attr_reader :manifest, :metadata, :lab_name, :source

  def self.clone(lab_url, lab_path)
    lab_path = File.basename(lab_url) if lab_path.empty?
    lab_url = "https://github.com/#{lab_url}" unless lab_url =~ URI::regexp || lab_url.start_with?("git@github.com")
    lab_address = Git::URL.parse(lab_url)

    lab_url = "https://github.com#{lab_address.path}" if lab_address.scheme != "https"
      
    if File.exists?(lab_path)
      puts "Lab already exists at #{lab_path}, deleting."
      self.delete_dir(lab_path)
    end
    
    lab_path = File.expand_path(lab_path.strip)

    self.new(path: lab_path, git_repo: Git::clone(lab_url, lab_path))
  end

  def initialize(path: ".", manifest_path: ".codelab/manifest.yml", git_repo: nil)
    @path = File.expand_path(path)
    if File.exists?("#{@path}/#{manifest_path}")
      @manifest_path = "#{@path}/#{manifest_path}"
      load_manifest
    end
        
    @repo = git_repo if git_repo
  end

  def progress
    @progress ||= if File.exists?("#{@path}/.codelab/progress.yml")
      YAML.load_file("#{@path}/.codelab/progress.yml")
    else
      {}
    end
  end

  def edit
    shell_command = ENV["SHELL"] || "bash"
    system("#{ENV["EDITOR"]} #{File.expand_path(path)}")
    exec "ruby -e \"Dir.chdir( '#{File.expand_path(path )}' ); exec '#{ENV["SHELL"]}'\""    
  end

  def metadata
    @metadata ||= @manifest.merge(YAML.load_file("#{@path}/.codelab/#{manifest["template"]}"))
  end

  def load_manifest
    @manifest ||= YAML.load_file(@manifest_path)
  end

  def repo
    @repo ||= Git.open(@path)
  end

  def source
    metadata["source"]
  end
  
  def lab_name
    metadata["name"] || File.basename(path)
  end  
  
  def repo_url
    repo.remote.url
  end

  def save
    repo.add(all: true)
    repo.commit("Saved progress on #{Time.now}")
    # repo.push("")
  end

  # def undo_last_commit
  #   repo.revert("HEAD~1..HEAD", { allow_empty: true })
  # end
end