def init
  super
  p sections
  sections.place(:rake_tasks).after_any(:alpha)
end

def rake_tasks
  @tasks = Registry.all(:rake_task)
  return if @tasks.empty?
  @tasks = @tasks.sort_by {|t| t.full_path == 'default' ? '_' : t.full_path }
  erb(:rake_tasks)
end