# frozen_string_literal: true

require "dry/cli"
require "faraday"

require_relative "cli/version"
require_relative "cli/utils"
require_relative "cli/reporter"
require_relative "cli/codelab"
require_relative "cli/codelabs/revpro_multiple"
require_relative "cli/codelabs/revpro"

require_relative "cli/command"

module Revpro
  module CLI
    require "yaml"
    require "uri"
    require "net/http"
    require "git"
    require "json"
    require "open3"
    require "nokogiri"

    class Error < StandardError; end

    module Commands
      extend Dry::CLI::Registry
      MENU = [
        { version: { aliases: ["v", "-v", "--version"] } },
        { start: {} },
        { open: {} },
        { info: {} },
        { util: {} },
        { test: {} },
        { save: {} },
        { submit: {} },
      ]

      MENU.each do |command|
        command_name = command.keys.first
        command_options = command.values.first

        require_relative "cli/commands/#{command_name}"

        register(command_name.to_s, const_get("#{command_name.capitalize}"), aliases: command_options.fetch(:aliases, []))
      end
    end
  end
end

# class Echo < Dry::CLI::Command
#   desc "Print inputut"

#   argument :input, desc: "Input to print"

#   example [
#     "             # Prints 'wuh?'",
#     "hello, folks # Prints 'hello, folks'"
#   ]

#   def call(input: nil, **)
#     if input.nil?
#       puts "wuh?"
#     else
#       puts input
#     end
#   end
# end

# class Start < Dry::CLI::Command
#   desc "Start Foo machinery"

#   argument :root, required: true, desc: "Root directory"

#   example [
#     "path/to/root # Start Foo at root directory"
#   ]

#   def call(root:, **)
#     puts "started - root: #{root}"
#   end
# end

# class Stop < Dry::CLI::Command
#   desc "Stop Foo machinery"

#   option :graceful, type: :boolean, default: true, desc: "Graceful stop"

#   def call(**options)
#     puts "stopped - graceful: #{options.fetch(:graceful)}"
#   end
# end

# class Exec < Dry::CLI::Command
#   desc "Execute a task"

#   argument :task, type: :string, required: true,  desc: "Task to be executed"
#   argument :dirs, type: :array,  required: false, desc: "Optional directories"

#   def call(task:, dirs: [], **)
#     puts "exec - task: #{task}, dirs: #{dirs.inspect}"
#   end
# end

# module Generate
#   class Configuration < Dry::CLI::Command
#     desc "Generate configuration"

#     option :apps, type: :array, default: [], desc: "Generate configuration for specific apps"

#     def call(apps:, **)
#       puts "generated configuration for apps: #{apps.inspect}"
#     end
#   end

#   class Test < Dry::CLI::Command
#     desc "Generate tests"

#     option :framework, default: "rspec", values: %w[minitest rspec]

#     def call(framework:, **)
#       puts "generated tests - framework: #{framework}"
#     end
#   end
# end

# require_relative "cli/version"
# require "dry/cli"

# module Revpro
#   module CLI
#     class Error < StandardError; end

#     module Commands
#       extend Dry::CLI::Registry

#       class Version < Dry::CLI::Command
#         desc "Print version"

#         def call(*)
#           puts "1.0.0"
#         end
#       end

#       register "version", Version, aliases: ["v", "-v", "--version"]
#       register "echo",    Echo
#       register "start",   Start
#       register "stop",    Stop
#       register "exec",    Exec

#       register "generate", aliases: ["g"] do |prefix|
#         prefix.register "config", Generate::Configuration
#         prefix.register "test",   Generate::Test
#       end
#     end
#   end
# end

# class Echo < Dry::CLI::Command
#   desc "Print input"

#   argument :input, desc: "Input to print"

#   example [
#     "             # Prints 'wuh?'",
#     "hello, folks # Prints 'hello, folks'"
#   ]

#   def call(input: nil, **)
#     if input.nil?
#       puts "wuh?"
#     else
#       puts input
#     end
#   end
# end

# class Start < Dry::CLI::Command
#   desc "Start Foo machinery"

#   argument :root, required: true, desc: "Root directory"

#   example [
#     "path/to/root # Start Foo at root directory"
#   ]

#   def call(root:, **)
#     puts "started - root: #{root}"
#   end
# end

# class Stop < Dry::CLI::Command
#   desc "Stop Foo machinery"

#   option :graceful, type: :boolean, default: true, desc: "Graceful stop"

#   def call(**options)
#     puts "stopped - graceful: #{options.fetch(:graceful)}"
#   end
# end

# class Exec < Dry::CLI::Command
#   desc "Execute a task"

#   argument :task, type: :string, required: true,  desc: "Task to be executed"
#   argument :dirs, type: :array,  required: false, desc: "Optional directories"

#   def call(task:, dirs: [], **)
#     puts "exec - task: #{task}, dirs: #{dirs.inspect}"
#   end
# end

# module Generate
#   class Configuration < Dry::CLI::Command
#     desc "Generate configuration"

#     option :apps, type: :array, default: [], desc: "Generate configuration for specific apps"

#     def call(apps:, **)
#       puts "generated configuration for apps: #{apps.inspect}"
#     end
#   end

#   class Test < Dry::CLI::Command
#     desc "Generate tests"

#     option :framework, default: "rspec", values: %w[minitest rspec]

#     def call(framework:, **)
#       puts "generated tests - framework: #{framework}"
#     end
#   end
# end

# require_relative "cli/version"
# require "dry/cli"

# module Revpro
#   module CLI
#     class Error < StandardError; end

#     module Commands
#       extend Dry::CLI::Registry

#       class Version < Dry::CLI::Command
#         desc "Print version"

#         def call(*)
#           puts "1.0.0"
#         end
#       end

#       register "version", Version, aliases: ["v", "-v", "--version"]
#       register "echo",    Echo
#       register "start",   Start
#       register "stop",    Stop
#       register "exec",    Exec

#       register "generate", aliases: ["g"] do |prefix|
#         prefix.register "config", Generate::Configuration
#         prefix.register "test",   Generate::Test
#       end
#     end
#   end
# end

# class Echo < Dry::CLI::Command
#   desc "Print input"

#   argument :input, desc: "Input to print"

#   example [
#     "             # Prints 'wuh?'",
#     "hello, folks # Prints 'hello, folks'"
#   ]

#   def call(input: nil, **)
#     if input.nil?
#       puts "wuh?"
#     else
#       puts input
#     end
#   end
# end

# class Start < Dry::CLI::Command
#   desc "Start Foo machinery"

#   argument :root, required: true, desc: "Root directory"

#   example [
#     "path/to/root # Start Foo at root directory"
#   ]

#   def call(root:, **)
#     puts "started - root: #{root}"
#   end
# end

# class Stop < Dry::CLI::Command
#   desc "Stop Foo machinery"

#   option :graceful, type: :boolean, default: true, desc: "Graceful stop"

#   def call(**options)
#     puts "stopped - graceful: #{options.fetch(:graceful)}"
#   end
# end

# class Exec < Dry::CLI::Command
#   desc "Execute a task"

#   argument :task, type: :string, required: true,  desc: "Task to be executed"
#   argument :dirs, type: :array,  required: false, desc: "Optional directories"

#   def call(task:, dirs: [], **)
#     puts "exec - task: #{task}, dirs: #{dirs.inspect}"
#   end
# end

# module Generate
#   class Configuration < Dry::CLI::Command
#     desc "Generate configuration"

#     option :apps, type: :array, default: [], desc: "Generate configuration for specific apps"

#     def call(apps:, **)
#       puts "generated configuration for apps: #{apps.inspect}"
#     end
#   end

#   class Test < Dry::CLI::Command
#     desc "Generate tests"

#     option :framework, default: "rspec", values: %w[minitest rspec]

#     def call(framework:, **)
#       puts "generated tests - framework: #{framework}"
#     end
#   end
# end

# require_relative "cli/version"
# require "dry/cli"

# module Revpro
#   module CLI
#     class Error < StandardError; end

#     module Commands
#       extend Dry::CLI::Registry

#       class Version < Dry::CLI::Command
#         desc "Print version"

#         def call(*)
#           puts "1.0.0"
#         end
#       end

#       register "version", Version, aliases: ["v", "-v", "--version"]
#       register "echo",    Echo
#       register "start",   Start
#       register "stop",    Stop
#       register "exec",    Exec

#       register "generate", aliases: ["g"] do |prefix|
#         prefix.register "config", Generate::Configuration
#         prefix.register "test",   Generate::Test
#       end
#     end
#   end
# end

# class Echo < Dry::CLI::Command
#   desc "Print input"

#   argument :input, desc: "Input to print"

#   example [
#     "             # Prints 'wuh?'",
#     "hello, folks # Prints 'hello, folks'"
#   ]

#   def call(input: nil, **)
#     if input.nil?
#       puts "wuh?"
#     else
#       puts input
#     end
#   end
# end

# class Start < Dry::CLI::Command
#   desc "Start Foo machinery"

#   argument :root, required: true, desc: "Root directory"

#   example [
#     "path/to/root # Start Foo at root directory"
#   ]

#   def call(root:, **)
#     puts "started - root: #{root}"
#   end
# end

# class Stop < Dry::CLI::Command
#   desc "Stop Foo machinery"

#   option :graceful, type: :boolean, default: true, desc: "Graceful stop"

#   def call(**options)
#     puts "stopped - graceful: #{options.fetch(:graceful)}"
#   end
# end

# class Exec < Dry::CLI::Command
#   desc "Execute a task"

#   argument :task, type: :string, required: true,  desc: "Task to be executed"
#   argument :dirs, type: :array,  required: false, desc: "Optional directories"

#   def call(task:, dirs: [], **)
#     puts "exec - task: #{task}, dirs: #{dirs.inspect}"
#   end
# end

# module Generate
#   class Configuration < Dry::CLI::Command
#     desc "Generate configuration"

#     option :apps, type: :array, default: [], desc: "Generate configuration for specific apps"

#     def call(apps:, **)
#       puts "generated configuration for apps: #{apps.inspect}"
#     end
#   end

#   class Test < Dry::CLI::Command
#     desc "Generate tests"

#     option :framework, default: "rspec", values: %w[minitest rspec]

#     def call(framework:, **)
#       puts "generated tests - framework: #{framework}"
#     end
#   end
# end
