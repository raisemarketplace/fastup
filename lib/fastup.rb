module Fastup
  extend self

  def apply!
    warn "fastup: building load path index"
    sp = SearchPath.new($LOAD_PATH)
    suffixes = Gem.suffixes.lazy

    warn "fastup: patching require"
    mod = Module.new do
      define_method(:require) do |name|
        path = suffixes.map{ |s| sp.lookup(name.to_s + s) rescue nil }.find do |p|
          p && File.file?(p)
        end

        # require the absolute path if found, otherwise fallback to original name
        ret = super(path || name)

        if ret && ENV['FASTUP_DEBUG']
          if path
            warn "fastup: loaded #{name} => #{path}"
          else
            warn "fastup: super #{name}"
          end
        end

        ret
      end
    end

    Object.prepend mod # normal "require 'somegem'" invokes this
    Kernel.singleton_class.prepend mod # explicit "Kernel.require 'somegem'"
  end

  module XFile
    def directory?(path)
      File.directory?(path)
    end

    def each_entry(dir, &block)
      Dir.new(dir).each do |e|
        next if e == '.' || e == '..'
        yield(e)
      end
    end
  end

  class SearchPath
    include XFile

    # Flatten the search path +paths+ by creating a tree of symlinks
    # at +dest+. For example, if the paths include +/usr/bin+, and
    # +/usr/lib+, then +dest+ will be a directory with symlinks +bin+
    # and +lib+ to the respective directories.
    def initialize(paths)
      @root = {}
      paths.each{ |path| @root = insert!(path) }
    end

    # given a path like 'a/b/c', determine if it exists in the tree, by trying root['a']['b']['c']
    #
    # if root['a'] is a string, then it should be 'somedir/a'
    #
    # if root['a']['b'] is a string, then it should be 'somedir/a/b'
    #
    # if root['a']['b']['c'] is a string, then it should be 'somedir/a/b/c'
    #
    # in all cases, the return value is 'somedir/a/b/c'
    def lookup(path, root=@root)
      case root
      when String
        if path.nil?
          return root
        else
          File.join(root, path)
        end
      when Hash
        head, rest = path.split(File::SEPARATOR, 2)
        lookup(rest, root[head])
      end
    end

    private
    
    # Assumption: target is the shortest path not yet tried. If the
    # shortest path cannot be linked directly, then if it's a
    # directory, each element of the directory will be inserted,
    # recursively.
    def insert!(target, root=@root)
      case root
      when String
        # conflict; can't insert ontop of non-directory
        return root unless directory?(root) && directory?(target)

        newroot = {}
        each_entry(root) do |entry|
          newroot[entry] = File.join(root, entry)
        end
        insert! target, newroot
      when Hash
        # conflict; can't insert non-directory ontop of directory
        return root unless directory?(target)

        each_entry(target) do |entry|
          if root.has_key?(entry)
            root[entry] = insert! File.join(target, entry), root[entry]
          else
            root[entry] = File.join(target, entry)
          end
        end
        root
      end
    end
  end
end
