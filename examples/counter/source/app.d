module examples.counter.app;

import std.stdio;
import red;

// Message definitions.
class Increment : IMessage
{
	string type()
	{
		return "increment";
	}
}

// Command definitions.
class PrintCounterState : ICommand
{
	string type()
	{
		return "print";
	}
}

// The program state.
struct Counter
{
	int value = 0;
}

// The function that tells the system what message comes next.
// In this example the next message is always Increment.
IMessage delegate() receiveMessage = delegate IMessage() { return new Increment(); };

void main()
{
	// RedSystem is parameterised with the program state. The constructor takes the initial state
	// and the receiveMessage function.
	RedSystem!Counter app = new RedSystem!Counter(Counter(), receiveMessage);

	// Here we register messages, in this case the increment message. The function has access to the
	// program state and can mutate it.
	app.registerMessage("increment", (Counter state, IMessage message) {
		state.value += 1;

		UpdateResult!Counter result = UpdateResult!Counter(
			state,
			[new PrintCounterState()]
		);

		if (state.value == 1_000)
		{
			result.exit = true;
		}

		return result;

	});

	// Here we register commands, in this case the print command. A command has read only access to the
	// program state and can create new messages via the MessageSender, which is a function that takes an
	// IMessage and puts it on the message queue of the RedSystem.
	app.registerCommand("print", (const ref Counter state, ICommand command, MessageSender send) {
		state.writeln;
	});

	app.run();
}
