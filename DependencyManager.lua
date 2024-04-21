
DependencyManager = {}

do
    DependencyManager.dependencies = {}

    function DependencyManager.register(name, dependency)
        DependencyManager.dependencies[name] = dependency
        env.info("DependencyManager - "..name.." registered")
    end

    function DependencyManager.get(name)
        return DependencyManager.dependencies[name]
    end
end

