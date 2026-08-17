module app;

import std.sumtype : SumType, match;

import red;
import tui.renderer;

struct Increment
{
    int increm;
}

struct Decrement
{
    int decrem;
}

struct NoCommand
{

}

alias Message = SumType!(Increment, Decrement);

alias Command = SumType!(NoCommand);

alias drawFunction = (int state, Renderer renderer) {
    renderer.box(10, 10, 20, 5);
};

alias updateFunction = (int state, Message message) {
    return message.match!((Increment m) => UpdateResult!(int,
            Command)(state + m.increm, [], false), (Decrement m) => UpdateResult!(int,
            Command)(state - m.decrem, [], false));
};

alias commandFunction = (int state, Command command) {
    Message[] messages;
    return messages;
};

Message delegate() receiveMessage = delegate Message() {
    return Message(Increment(1));
};

void main()
{
    RedSystem!(int, Message, Command) app = new RedSystem!(int, Message, Command)(1,
            receiveMessage, updateFunction, commandFunction, drawFunction);
    app.run();
}
