require "crystal/system/fiber"

class Fiber
  # :nodoc:
  class StackPool
    STACK_SIZE = 8 * 1024 * 1024

    def initialize
      @deque = Deque(Void*).new
    end

    # Removes and frees at most *count* stacks from the top of the pool,
    # returning memory to the operating system.
    def collect(count = lazy_size // 2) : Nil
      count.times do
        if stack = @deque.shift?
          Crystal::System::Fiber.free_stack(stack, STACK_SIZE)
        else
          return
        end
      end
    end

    def collect_loop(every = 5.seconds) : Nil
      loop do
        sleep every
        collect
      end
    end

    # Removes a stack from the bottom of the pool, or allocates a new one.
    def checkout : {Void*, Void*}
      stack = @deque.pop? || Crystal::System::Fiber.allocate_stack(STACK_SIZE)
      {stack, stack + STACK_SIZE}
    end

    # Appends a stack to the bottom of the pool.
    def release(stack) : Nil
      @deque.push(stack)
    end

    # Returns the approximated size of the pool. It may be equal or slightly
    # bigger or smaller than the actual size.
    def lazy_size : Int32
      @deque.size
    end
  end
end
