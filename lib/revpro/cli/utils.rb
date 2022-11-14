module Revpro::CLI::Utils

  module ClassMethods
    def delete_dir(dir_path)
      FileUtils.rm_rf(File.expand_path(dir_path))
    end

    def change_working_dir(dir_path)
    end
  end
end