module Revpro::CLI::Codelabs
  class Revpro < Revpro::CLI::Codelab
    def github_username
      @github_username = infer_github_username_from_remote_url      
    end

    private
      def infer_github_username_from_remote_url(scheme: "https")
        repo.remote.url.split("/")[-2].strip if scheme == "https"
      end
  end
end