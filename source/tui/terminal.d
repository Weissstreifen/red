module tui.terminal;

import arsd.terminal;

import tui.input;

import red;

Subscription!M terminalSubscription(M)(RealTimeConsoleInput* input, EventHandler!M eventHandler)
{
    return Subscription!M((MessageSender!M send) {

        while (true)
        {
            auto arsdEvent = input.nextEvent();

            convertEvent(arsdEvent, (RedInputEvent event) {
                eventHandler(event, send);
            });
        }
    });
}
