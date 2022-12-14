module Revpro::CLI
  module Utils
    module ClassMethods
      def delete_dir(dir_path)
        FileUtils.rm_rf(File.expand_path(dir_path))
      end

      def change_working_dir(dir_path)
      end

      def global_config_dir
        if  ENV["GITPOD_WORKSPACE_CONTEXT"] # env_gitpod_workspace_context
          home_dir = "/workspace/.revpro"                
        else
          home_dir = "#{ENV["HOME"]}/.revpro"
        end
      end


      def global_config_path
        if  ENV["GITPOD_WORKSPACE_CONTEXT"] # env_gitpod_workspace_context
          home_dir = "/workspace"                
        else
          home_dir = ENV["HOME"]
        end
  
        "/#{global_config_dir}/config.yml"
      end

      def global_config_exists?
        return File.exists?(global_config_path)
      end

      def global_config_data
        YAML.load_file(global_config_path)
      end
    end
  end
end