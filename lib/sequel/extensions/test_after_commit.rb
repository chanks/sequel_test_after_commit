module Sequel
  module TestAfterCommit
    def remove_transaction(conn, committed)
      level = savepoint_level(conn)

      if h = _trans(conn)
        if after_commit = h[:after_commit]
          if hooks = after_commit.delete(level)
            hooks.each(&:call) if committed
          end
        end

        if after_rollback = h[:after_rollback]
          if hooks = after_rollback.delete(level)
            hooks.each(&:call) unless committed
          end
        end
      end

      super
    end

    def after_commit(opts=OPTS, &block)
      raise Error, "must provide block to after_commit" unless block
      synchronize(opts[:server]) do |conn|
        if h = _trans(conn)
          raise Error, "cannot call after_commit in a prepared transaction" if h[:prepare]
          level = savepoint_level(conn)
          hooks = h[:after_commit] ||= {}
          hooks[level] ||= []
          hooks[level] << block
        else
          yield
        end
      end
    end

    def after_rollback(opts=OPTS, &block)
      raise Error, "must provide block to after_rollback" unless block
      synchronize(opts[:server]) do |conn|
        if h = _trans(conn)
          raise Error, "cannot call after_rollback in a prepared transaction" if h[:prepare]
          level = savepoint_level(conn)
          hooks = h[:after_rollback] ||= {}
          hooks[level] ||= []
          hooks[level] << block
        end
      end
    end

    # The methods that usually trigger the callbacks become no-ops.
    def after_transaction_commit(conn);   end
    def after_transaction_rollback(conn); end
  end

  Database.register_extension(:test_after_commit) { |db| (class << db; self; end).send(:prepend, TestAfterCommit) }
end
