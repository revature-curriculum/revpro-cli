module Revpro::CLI::Codelabs
  class RevproMultiple < Revpro::CLI::Codelab
    def self.open(lab_path: nil, git_repo: nil)
      new(lab_path: lab_path, git_repo: git_repo).tap do |codelab|
        codelab.open(lab_path)        
      end
    end

    def initialize(lab_path:, manifest_path: nil, git_repo: nil)
      # Lab path is the path to the lab directory
      @full_lab_path = File.expand_path(lab_path.strip)
      # Manifest path is the path to the manifest.yml file, in a MultiLab situation that will always be in the root directory of the git repository.
      # lab_path is going to be either:
      # pep-labs-1/Intro_To_Java/Comparisons
      # Intro_To_Java/Comparisons
      # Comparisons
      
      puts "Can't find a lab at #{@full_lab_path}." and exit if !File.exists?(@full_lab_path) || !File.exists?("#{@full_lab_path}/pom.xml")
      @lab_name = @full_lab_path.split("/")[-2..-1].join("/")
      @monorepo_root_path = ["#{@full_lab_path}/./", "#{@full_lab_path}/../", "#{@full_lab_path}/../../", "#{@full_lab_path}/../../../", "#{@full_lab_path}/../../../../"].detect{|p| File.exists?("#{p}/.codelab/manifest.yml")}
      if @monorepo_root_path
        @manifest_path = "#{@monorepo_root_path}/.codelab/manifest.yml"
        @metadata_path = @manifest_path.gsub("manifest.yml", "#{manifest["template"]}")
        @repo = Git.open(@monorepo_root_path)                         
      else
        puts "You must run `open` command from within a lab directory."
        exit
      end
    end

    def open(lab_path)
      puts "Opening #{@lab_name} in #{@monorepo_root_path}"
      save_and_commit
      checkout_lab_branch(@lab_name)
      update_manifest_current_lab(@lab_name)
      open_editor(lab_path)
      cd_into_lab(lab_path)
    end

    def update_manifest_current_lab(lab_path)
      metadata["previous_lab"] = metadata["current_lab"]
      metadata["current_lab"] = lab_path
      File.open(@metadata_path, "w") do |f|
        f.write(metadata.to_yaml)
      end
    end

    def save_and_commit
      repo.add(all: true, verify: false)
      repo.commit_all("Saved progress on #{@lab_name} #{Time.now}", allow_empty: true)
    end    

    def checkout_lab_branch(branch_name)
      if repo.branches.local.map(&:name).include?(branch_name)
        repo.checkout(branch_name)
      else
        repo.checkout(branch_name, new_branch: true)
      end
    end

    def open_editor(path)
      shell_command = ENV["SHELL"] || "bash"
      system("#{ENV["EDITOR"]} #{File.expand_path(path)}")
    end
  
    def cd_into_lab(path)
      exec "ruby -e \"Dir.chdir( '#{File.expand_path(path )}' ); exec '#{ENV["SHELL"]}'\""    
    end
    
    def github_username
      @github_username = infer_github_username_from_remote_url      
    end

    def progress
      @progress ||= if File.exists?("#{@path}/.codelab/progress.yml")
        YAML.load_file("#{@path}/.codelab/progress.yml")
      else
        {}
      end
    end
    
    def metadata
      @metadata ||= YAML.load_file(@metadata_path)
    end
  
    def manifest
      @manifest ||= YAML.load_file(@manifest_path)
    end
  
    def repo(path = @path)
      @repo ||= Git.open(@path)
    end

    def lab_name
      metadata["name"] || File.basename(path)
    end  
    
    def repo_url
      repo.remote.url
    end

    private
      def infer_github_username_from_remote_url(scheme: "https")
        repo.remote.url.split("/")[-2].strip if scheme == "https"
      end
  end
end


      # you're either in something like this:
      # ~/pep-labs-1 
      # or ~/pep-labs-1/topic-1/lab-1
      # or ~/pep-labs-1/lab-1

      # or you're just entirely in the wrong folder
      # or /workspace
      # for this to work, you'd have to infer the path from the last current_global_lab or something.

      # binding.pry
      # # @main_repo_path
      # # @lab_name
      # # @manifest_path 
      # # @metadata_path

      # @manifest_path = ["./.codelab/manifest.yml", "../.codelab/manifest.yml", "../../.codelab/manifest.yml"].detect{|p| File.exists?(p)}
      # if @manifest_path
      #   @repo = Git.open(possible_manifest.gsub(".codelab/manifest.yml", "")) 
      #   @manifest_path = possible_manifest          
      #   @metadata_path = @manifest_path.gsub("manifest.yml", "#{manifest["template"]}")                        
      # else
      #   puts "You must run `open` command from within a lab directory."
      #   exit
      # end

      # @repo_format = metadata["format"] || "revpro-single" 