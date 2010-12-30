module YARD  
  Tags::Library.define_tag "Task Dependencies", :task_deps
  Tags::Library.visible_tags << :task_deps
  Templates::Engine.register_template_path File.dirname(__FILE__) + '/../templates'
  
  module CodeObjects
    module Rake
      class NamespaceObject < CodeObjects::NamespaceObject
        PREFIX = "!rake:"
        alias tasks children
        def path; parent == Registry.root ? "#{PREFIX}#{name}" : super end
        def full_path; path.sub(/^#{PREFIX}/, '') end
        def type; :rake_namespace end
        def sep; ':' end
      end
      
      class TaskObject < CodeObjects::Base
        def type; :rake_task end
        def full_path; path.sub(/^#{NamespaceObject::PREFIX}/, '') end
        def sep; ':' end
      end
    end
  end
  
  module Handlers
    class Processor; attr_accessor :desc_comments end
    
    module Rake
      class Base < Ruby::Base; namespace_only; in_file "Rakefile" end
      
      class NamespaceHandler < Base
        handles method_call(:namespace)
        
        process do
          name = statement.parameters[0].jump(:ident, :tstring_content).source
          obj = CodeObjects::Rake::NamespaceObject.new(namespace, name)
          register(obj)
          parse_block(statement.last.last, namespace: obj)
        end
      end
      
      class DescHandler < Base
        handles method_call(:desc)
        
        process do
          parser.desc_comments = 
            statement.parameters[0].jump(:tstring_content).source
        end
      end
      
      class TaskHandler < Base
        handles method_call(:task)
        
        process do
          arg = statement.parameters[0][0]
          name = arg.jump(:ident, :tstring_content).source
          deps = arg.type == :assoc ? arg[1].source : nil
          obj = CodeObjects::Rake::TaskObject.new(namespace, name)
          register(obj)
          
          if parser.desc_comments && obj.docstring.blank?
            obj.docstring += parser.desc_comments
          end
          obj.docstring.add_tag Tags::Tag.new(:task_deps, deps) if deps
          parser.desc_comments = nil
        end
      end
    end
  end
end
