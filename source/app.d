module app;
import std.datetime.stopwatch;

import red;

import std.stdio;

class Increment : IMessage
{
    string type()
    {
        return "increment";
    }
}

class PrintCounterState : ICommand
{
    string type()
    {
        return "print";
    }
}

struct Counter
{
    int value = 0;
}

IMessage delegate() receiveMessage = delegate IMessage() { return new Increment(); };

void main()
{
    enum N = 1_000_000;

    RedSystem!Counter app = new RedSystem!Counter(Counter(), receiveMessage);
    app.registerMessage("increment", (Counter state, IMessage message) {
        state.value += 1;

        UpdateResult!Counter result = UpdateResult!Counter(
            state,
            []
        );

        if (state.value == N)
        {
            result.exit = true;
        }

        return result;
    });

    auto sw = StopWatch(AutoStart.yes);
    app.run();
    auto elapsed = sw.peek();

    writeln("Processed: ", N, " messages.");
    writeln("Elapsed: ", elapsed);
    writeln("ns/message: ", elapsed.total!"nsecs" / cast(double) N);
}
