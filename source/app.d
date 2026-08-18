module app;

import std.sumtype : SumType, match;

import red;
import tui.renderer;
import tui.input;

struct Increment
{
    int increm;
}

struct Decrement
{
    int decrem;
}

struct Quit
{

}

struct NoCommand
{

}

alias Message = SumType!(Increment, Decrement, Quit);
alias Command = SumType!(NoCommand);

import std.conv;

void draw(int state, Renderer renderer)
{
    renderer.box(state, 10, 20, 5);
    renderer.text(state + 2, 12, state.to!string);
}

UpdateResult!(int, Command) update(int state, Message message)
{

    return message.match!((Increment m) => UpdateResult!(int,
            Command)(state + m.increm, [], false), (Decrement m) => UpdateResult!(int,
            Command)(state - m.decrem, [], false),
            (Quit m) => UpdateResult!(int, Command)(state, [], true));
}

Message[] command(int state, Command command)
{
    return [];
}

void eventHandler(RedInputEvent event, MessageSender!(Message) sender)
{
    event.match!((RedKeyEvent key) {
        if (!key.pressed)
        {
            return;
        }

        if (key.key == RedKeyEvent.Key.CHARACTER)
        {
            if (key.character == 'd')
                sender(Message(Increment(1)));

            if (key.character == 'a')
                sender(Message(Decrement(1)));
        }
    }, (RedMouseEvent mouse) {
        // Ignore mouse events
    }, (RedResizeEvent resize) {
        // Ignore resize events
    }, (RedPasteEvent paste) {
        // Ignore paste events
    }, (RedInterruptEvent interrupt) {
        // Send Quit Message when interrupt occurs
        sender(Message(Quit()));
    });
}

void main()
{
    RedSystem!(int, Message, Command) app = new RedSystem!(int, Message, Command)(1,
            &update, &command, &draw, &eventHandler);
    app.run();
}
