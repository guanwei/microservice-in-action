namespace :quality do
  begin
    require 'rubocop/rake_task'

    RuboCop::RakeTask.new(:rubocop) do |task|
      task.patterns = %w{
        app/**/*.rb
        config/**/*.rb
        lib/**/*.rb
        spec/**/*.rb
      }
    end
  rescue LoadError
    warn "rubocop not available, rake task not provided."
  end
end