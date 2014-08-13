require 'spec_helper'

describe Sequel::TestAfterCommit do
  before do
    @db = Sequel.mock
    @db.extension :test_after_commit
    @callbacks = []
  end

  it "should still run after_commit callbacks immediately when outside a transaction" do
    @db.after_commit { @callbacks << :after_commit }
    @callbacks.should == [:after_commit]
  end

  it "should still not run after_rollback hooks at all when outside a transaction" do
    @db.after_rollback { @callbacks << :after_rollback }
    @callbacks.should == []
  end

  it "should still not run hooks until after the transaction finishes" do
    @db.transaction do
      @db.after_commit   { @db.execute "after_commit"   }
      @db.after_rollback { @db.execute "after_rollback" }
    end

    @db.sqls.should == ["BEGIN", "COMMIT", "after_commit"]
    @db.sqls.clear

    @db.transaction do
      @db.after_commit   { @db.execute "after_commit"   }
      @db.after_rollback { @db.execute "after_rollback" }
      raise Sequel::Rollback
    end

    @db.sqls.should == ["BEGIN", "ROLLBACK", "after_rollback"]
  end

  it "should not interfere with the usual operation of the hooks when a transaction commits" do
    @db.transaction do
      @db.after_commit { @callbacks << :first_after_commit }
      @db.after_commit { @callbacks << :second_after_commit }
      @db.after_rollback { @callbacks << :first_after_rollback }
      @db.after_rollback { @callbacks << :second_after_rollback }
      @callbacks.should == []
    end

    @callbacks.should == [:first_after_commit, :second_after_commit]
  end

  it "should not interfere with the usual operation of the hooks when a transaction rolls back" do
    @db.transaction do
      @db.after_commit { @callbacks << :first_after_commit }
      @db.after_commit { @callbacks << :second_after_commit }
      @db.after_rollback { @callbacks << :first_after_rollback }
      @db.after_rollback { @callbacks << :second_after_rollback }
      @callbacks.should == []
      raise Sequel::Rollback
    end

    @callbacks.should == [:first_after_rollback, :second_after_rollback]
  end

  it "should run after_commit callbacks after the subtransaction in which they are declared commits" do
    @db.transaction do
      @db.after_commit   { @callbacks << :first_after_commit }
      @db.after_rollback { @callbacks << :first_after_rollback }
      @callbacks.should == []

      @db.transaction :savepoint => true do
        @db.after_commit   { @callbacks << :second_after_commit }
        @db.after_rollback { @callbacks << :second_after_rollback }
        @callbacks.should == []
      end

      @callbacks.should == [:second_after_commit]

      @db.transaction :savepoint => true do
        @db.after_commit   { @callbacks << :third_after_commit }
        @db.after_rollback { @callbacks << :third_after_rollback }
        @callbacks.should == [:second_after_commit]
      end

      @callbacks.should == [:second_after_commit, :third_after_commit]
    end

    @callbacks.should == [:second_after_commit, :third_after_commit, :first_after_commit]
  end

  it "should run new after_commit callbacks immediately when in the after_commit stage" do
    @db.transaction do
      @db.after_commit do
        @db.after_commit { @callbacks << :after_commit_1_1 }
        @callbacks << :after_commit_1
        @db.after_commit { @callbacks << :after_commit_1_2 }
      end
      @callbacks.should == []

      @db.transaction :savepoint => true do
        @db.after_commit do
          @db.after_commit { @callbacks << :after_commit_2_1 }
          @callbacks << :after_commit_2
          @db.after_commit { @callbacks << :after_commit_2_2 }
        end
        @callbacks.should == []
      end

      @callbacks.should == [:after_commit_2_1, :after_commit_2, :after_commit_2_2]

      @db.transaction :savepoint => true do
        @db.after_commit do
          @db.after_commit { @callbacks << :after_commit_3_1 }
          @callbacks << :after_commit_3
          @db.after_commit { @callbacks << :after_commit_3_2 }
        end
        @callbacks.should == [:after_commit_2_1, :after_commit_2, :after_commit_2_2]
      end

      @callbacks.should == [:after_commit_2_1, :after_commit_2, :after_commit_2_2, :after_commit_3_1, :after_commit_3, :after_commit_3_2]
    end

    @callbacks.should == [:after_commit_2_1, :after_commit_2, :after_commit_2_2, :after_commit_3_1, :after_commit_3, :after_commit_3_2, :after_commit_1_1, :after_commit_1, :after_commit_1_2]
  end

  it "should run after_rollback callbacks after the subtransaction in which they are declared rolls back" do
    @db.transaction do
      @db.after_commit   { @callbacks << :first_after_commit }
      @db.after_rollback { @callbacks << :first_after_rollback }
      @callbacks.should == []

      @db.transaction :savepoint => true do
        @db.after_commit   { @callbacks << :second_after_commit }
        @db.after_rollback { @callbacks << :second_after_rollback }
        @callbacks.should == []
        raise Sequel::Rollback
      end

      @callbacks.should == [:second_after_rollback]

      @db.transaction :savepoint => true do
        @db.after_commit   { @callbacks << :third_after_commit }
        @db.after_rollback { @callbacks << :third_after_rollback }
        @callbacks.should == [:second_after_rollback]
        raise Sequel::Rollback
      end

      @callbacks.should == [:second_after_rollback, :third_after_rollback]
      raise Sequel::Rollback
    end

    @callbacks.should == [:second_after_rollback, :third_after_rollback, :first_after_rollback]
  end

  it "should run after_commit hooks correctly with auto_savepoint" do
    @db.transaction :auto_savepoint => true do
      @db.after_commit   { @callbacks << :first_after_commit }
      @db.after_rollback { @callbacks << :first_after_rollback }
      @callbacks.should == []

      @db.transaction do
        @db.after_commit   { @callbacks << :second_after_commit }
        @db.after_rollback { @callbacks << :second_after_rollback }
        @callbacks.should == []
      end

      @callbacks.should == [:second_after_commit]
    end

    @callbacks.should == [:second_after_commit, :first_after_commit]
  end

  it "should run after_rollback hooks correctly with auto_savepoint" do
    @db.transaction :auto_savepoint => true do
      @db.after_commit   { @callbacks << :first_after_commit }
      @db.after_rollback { @callbacks << :first_after_rollback }
      @callbacks.should == []

      @db.transaction do
        @db.after_commit   { @callbacks << :second_after_commit }
        @db.after_rollback { @callbacks << :second_after_rollback }
        @callbacks.should == []
        raise Sequel::Rollback
      end

      @callbacks.should == [:second_after_rollback]
      raise Sequel::Rollback
    end

    @callbacks.should == [:second_after_rollback, :first_after_rollback]
  end

  it "doesn't affect the behavior of databases not extended with it" do
    @other = Sequel.mock

    @other.transaction do
      @other.after_commit { @callbacks << :first_after_commit }
      @callbacks.should == []

      @other.transaction :savepoint => true do
        @other.after_commit { @callbacks << :second_after_commit }
        @callbacks.should == []
      end

      @callbacks.should == []
    end

    @callbacks.should == [:first_after_commit, :second_after_commit]
  end
end
