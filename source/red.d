module red;

import std.typecons;

import tui.renderer;

import arsd.terminal;

struct UpdateResult(S, C)
{
    S state;
    C[] commands;
    bool exit;
}

alias MessageSender(M) = void delegate(M message);
alias MessageReceiver(M) = M delegate();
alias CommandFunction(S, M, C) = M[]delegate(S state, C command);
alias DrawFunction(S) = void delegate(S state, Renderer renderer);
alias UpdateFunction(S, M, C) = UpdateResult!(S, C) delegate(S state, M message);

public class RedSystem(S, M, C)
{

    private M[] messageQueue;
    private MessageReceiver!(M) messageReceiver;
    private DrawFunction!(S) drawFunction;
    private UpdateFunction!(S, M, C) updateFunction;
    private CommandFunction!(S, M, C) commandFunction;
    private bool running = true;
    private Renderer renderer;

    S currentState;

    this(S initialState, MessageReceiver!(M) messageReceiver, UpdateFunction!(S,
            M, C) updateFunction, CommandFunction!(S, M, C) commandFunction,
            DrawFunction!(S) drawFunction)
    {
        this.currentState = initialState;
        this.messageReceiver = messageReceiver;
        this.drawFunction = drawFunction;
        this.updateFunction = updateFunction;
        this.commandFunction = commandFunction;
    }

    public void sendMessage(M message)
    {
        this.messageQueue ~= message;
    }

    private UpdateResult!(S, C) update(S state, M message)
    {
        return this.updateFunction(state, message);
    }

    private void receiveMessage()
    {
        //TODO: Make blocking
        Nullable!M message = this.messageReceiver();

        if (!message.isNull)
        {
            this.sendMessage(message.get());
        }
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

        // Draw initial state
        this.renderFrame();

        while (this.running)
        {
            this.receiveMessage();

            while (this.messageQueue.length > 0)
            {
                M message = this.messageQueue[0];
                this.messageQueue = this.messageQueue[1 .. $];

                UpdateResult!(S, C) result = this.update(this.currentState, message);
                if (result.exit)
                {
                    this.running = false;
                }
                this.currentState = result.state;
                this.executeCommands(result.commands);
                this.renderFrame();
            }
        }
    }
}
