module app;

import red;
import tui.renderer;

class Increment : IMessage
{
    string type()
    {
        return "increment";
    }
}

alias draw = (int state, Renderer renderer) { renderer.box(10, 10, 20, 5); };

IMessage delegate() receiveMessage = delegate IMessage() { return new Increment(); };

void main()
{
    RedSystem!int app = new RedSystem!int(1, receiveMessage, draw);
    app.registerMessage("increment", (int state, IMessage msg) {
        bool end = false;
        if (state == 10_000_000)
        {
            end = true;
        }
        return UpdateResult!int(state + 1, [], end);
    });
    app.run();
}
