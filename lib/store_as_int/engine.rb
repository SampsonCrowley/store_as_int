module StoreAsInt
  class Engine < ::Rails::Engine
    isolate_namespace StoreAsInt
    config.autoload_paths += Dir["#{config.root}/lib/**/"]
  end
end
