module red;

import tui.renderer;

import arsd.terminal;

interface IMessage
{
    string type();
}

interface ICommand
{
    string type();
}

struct UpdateResult(S)
{
    S state;
    ICommand[] commands;
    bool exit;
}

alias MessageHandler(S) = UpdateResult!(S) delegate(S state, IMessage message);
alias MessageSender = void delegate(IMessage message);
alias CommandHandler(S) = void delegate(const ref S state, ICommand command, MessageSender send);
alias MessageType = string;
alias CommandType = string;
alias MessageReceiver = IMessage delegate();
alias DrawFunction(S) = void delegate(S state, Renderer renderer);

public class RedSystem(S)
{

    private MessageHandler!(S)[MessageType] messageRegistry;
    private CommandHandler!(S)[CommandType] commandRegistry;
    private IMessage[] messageQueue;
    private MessageReceiver messageReceiver;
    private DrawFunction!(S) drawFunction;
    private bool running = true;
    private Renderer renderer;

    S currentState;

    this(S initialState, MessageReceiver messageReceiver, DrawFunction!(S) drawFunction)
    {
        this.currentState = initialState;
        this.messageReceiver = messageReceiver;
        this.drawFunction = drawFunction;
    }

    public void sendMessage(IMessage message)
    {
        this.messageQueue ~= message;
    }

    public void registerMessage(MessageType messageType, MessageHandler!(S) messageHandler)
    {
        this.messageRegistry[messageType] = messageHandler;
    }

    public void registerCommand(CommandType commandType, CommandHandler!(S) commandHandler)
    {
        this.commandRegistry[commandType] = commandHandler;
    }

    private UpdateResult!(S) update(S state, IMessage message)
    {
        auto handler = message.type in messageRegistry;

        if (handler == null)
        {
            throw new Exception("Message type: " ~ message.type ~ " not registered.");
        }

        return (*handler)(state, message);
    }

    private void receiveMessage()
    {
        IMessage message = this.messageReceiver();

        if (message !is null)
        {
            this.sendMessage(message);
        }
    }

    private void executeCommands(ICommand[] commands)
    {
        foreach (ICommand command; commands)
        {

            auto handler = command.type() in this.commandRegistry;

            if (handler == null)
            {
                throw new Exception("Command type: " ~ command.type ~ " not registered.");
            }

            (*handler)(this.currentState, command, &this.sendMessage);
        }
    }

    public void run()
    {
        Terminal terminal = Terminal(ConsoleOutputType.cellular);
        this.renderer = new Renderer(&terminal);

        scope (exit)
        {
            terminal.destroy();
        }

        while (this.running)
        {
            this.receiveMessage();

            while (this.messageQueue.length > 0)
            {
                IMessage message = this.messageQueue[0];
                this.messageQueue = this.messageQueue[1 .. $];

                UpdateResult!(S) result = this.update(this.currentState, message);
                if (result.exit)
                {
                    this.running = false;
                }
                this.currentState = result.state;
                this.executeCommands(result.commands);
                this.renderer.beginFrame();
                this.drawFunction(this.currentState, this.renderer);
                this.renderer.flush();
            }
        }
    }
}
