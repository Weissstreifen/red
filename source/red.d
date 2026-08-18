module red;

import std.typecons;

import core.thread;
import core.sync.mutex;
import core.sync.condition;

import tui.renderer;
import tui.terminal;
import tui.input;

import arsd.terminal;

alias MessageSender(M) = void delegate(M message);
alias SubscriptionFunction(M) = void delegate(MessageSender!(M) send);
struct Subscription(M)
{
    SubscriptionFunction!(M) start;
}

struct UpdateResult(S, C)
{
    S state;
    C[] commands;
    bool exit;
}

alias CommandFunction(S, M, C) = M[]function(S state, C command);
alias DrawFunction(S) = void function(S state, Renderer renderer);
alias UpdateFunction(S, M, C) = UpdateResult!(S, C) function(S state, M message);
alias EventHandler(M) = void function(RedInputEvent event, MessageSender!(M) send);

public class RedSystem(S, M, C)
{

    private M[] messageQueue;
    private DrawFunction!(S) drawFunction;
    private UpdateFunction!(S, M, C) updateFunction;
    private CommandFunction!(S, M, C) commandFunction;
    private Subscription!(M)[] subscriptions;
    private bool running = true;
    private Renderer renderer;
    private EventHandler!(M) eventHandler;
    private Mutex messageQueueMutex;
    private Condition messageQueueCondition;

    S currentState;

    this(S initialState, UpdateFunction!(S, M, C) updateFunction,
            CommandFunction!(S, M, C) commandFunction,
            DrawFunction!(S) drawFunction, EventHandler!(M) eventHandler)
    {
        this.currentState = initialState;
        this.drawFunction = drawFunction;
        this.updateFunction = updateFunction;
        this.commandFunction = commandFunction;
        this.eventHandler = eventHandler;
        this.messageQueueMutex = new Mutex();
        this.messageQueueCondition = new Condition(this.messageQueueMutex);
    }

    public void sendMessage(M message)
    {
        synchronized (this.messageQueueMutex)
        {
            this.messageQueue ~= message;
            this.messageQueueCondition.notify();
        }
    }

    private UpdateResult!(S, C) update(S state, M message)
    {
        return this.updateFunction(state, message);
    }

    private void executeCommands(C[] commands)
    {
        foreach (C command; commands)
        {
            M[] messages = this.commandFunction(this.currentState, command);
            foreach (M message; messages)
            {
                this.sendMessage(message);
            }
        }
    }

    private M receiveMessage()
    {
        synchronized (this.messageQueueMutex)
        {
            while (this.messageQueue.length == 0 && this.running)
            {
                this.messageQueueCondition.wait();
            }

            if (!this.running)
            {
                return M.init;
            }

            M message = this.messageQueue[0];
            this.messageQueue = this.messageQueue[1 .. $];

            return message;
        }
    }

    private void renderFrame()
    {
        this.renderer.beginFrame();
        this.drawFunction(this.currentState, this.renderer);
        this.renderer.flush();
    }

    public void run()
    {
        Terminal terminal = Terminal(ConsoleOutputType.cellular);
        this.renderer = new Renderer(&terminal);

        scope (exit)
        {
            terminal.destroy();
        }

        auto input = RealTimeConsoleInput(&terminal, ConsoleInputFlags.allInputEvents);
        this.subscriptions ~= terminalSubscription!(M)(&input, this.eventHandler);

        foreach (subscription; subscriptions)
        {
            auto thread = new Thread({ subscription.start(&this.sendMessage); });

            thread.start();
        }
        // Draw initial state
        this.renderFrame();

        while (this.running)
        {
            M message = this.receiveMessage();

            if (!this.running)
            {
                break;
            }

            UpdateResult!(S, C) result = this.update(this.currentState, message);

            if (result.exit)
            {
                this.running = false;
                synchronized (this.messageQueueMutex)
                {
                    this.messageQueueCondition.notifyAll();
                }
            }

            this.currentState = result.state;
            this.executeCommands(result.commands);
            this.renderFrame();
        }
    }
}
