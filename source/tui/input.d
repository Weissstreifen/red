module tui.input;
import std.sumtype;

import arsd.terminal;

struct RedKeyEvent
{
    enum Key
    {
        CHARACTER,
        ESCAPE,
        F1,
        F2,
        F3,
        F4,
        F5,
        F6,
        F7,
        F8,
        F9,
        F10,
        F11,
        F12,
        LEFT,
        RIGHT,
        UP,
        DOWN,
        INSERT,
        DELETE,
        HOME,
        END,
        PAGE_UP,
        PAGE_DOWN,
        SCROLL_LOCK
    }

    Key key;
    dchar character;

    bool pressed;

    bool shift;
    bool control;
    bool alt;
    bool meta;
}

struct RedMouseEvent
{
    enum Action
    {
        MOVED,
        PRESSED,
        RELEASED,
        CLICKED
    }

    uint buttons;

    Action action;

    int x;
    int y;

    bool shift;
    bool control;
    bool alt;
    bool meta;
}

struct RedResizeEvent
{
    int oldWidth;
    int oldHeight;

    int width;
    int height;
}

struct RedInterruptEvent
{
}

struct RedPasteEvent
{
    string text;
}

alias RedInputEvent = SumType!(RedKeyEvent, RedMouseEvent, RedResizeEvent,
        RedPasteEvent, RedInterruptEvent);

alias RedInputSender = void delegate(RedInputEvent event);

void convertEvent(InputEvent event, RedInputSender send)
{
    import std.stdio;

    final switch (event.type)
    {
    case InputEvent.Type.KeyboardEvent:
        auto key = event.get!(InputEvent.Type.KeyboardEvent);
        writeln("KEY: ", key.which, " ctrl=", (key.modifierState & ModifierState.control) != 0);
        send(convertKeyboardEvent(event.get!(InputEvent.Type.KeyboardEvent)));
        break;

    case InputEvent.Type.PasteEvent:
        send(RedInputEvent(RedPasteEvent(event.get!(InputEvent.Type.PasteEvent).pastedText)));
        break;

    case InputEvent.Type.MouseEvent:
        send(convertMouseEvent(event.get!(InputEvent.Type.MouseEvent)));
        break;

    case InputEvent.Type.SizeChangedEvent:
        send(convertResizeEvent(event.get!(InputEvent.Type.SizeChangedEvent)));
        break;

    case InputEvent.Type.UserInterruptionEvent:
    case InputEvent.Type.HangupEvent:
        send(RedInputEvent(RedInterruptEvent()));
        break;
    case InputEvent.Type.CharacterEvent:
    case InputEvent.Type.NonCharacterKeyEvent:
    case InputEvent.Type.LinkEvent:
    case InputEvent.Type.EndOfFileEvent:
    case InputEvent.Type.CustomEvent:
        break;
    }
}

private RedInputEvent convertKeyboardEvent(KeyboardEvent event)
{
    RedKeyEvent result;

    result.pressed = event.pressed;

    result.shift = (event.modifierState & ModifierState.shift) != 0;

    result.control = (event.modifierState & ModifierState.control) != 0;

    result.alt = (event.modifierState & ModifierState.alt) != 0;

    result.meta = (event.modifierState & ModifierState.meta) != 0;

    if (event.isNonCharacterKey())
    {
        switch (event.which)
        {
        case KeyboardEvent.Key.escape:
            result.key = RedKeyEvent.Key.ESCAPE;
            break;

        case KeyboardEvent.Key.F1:
            result.key = RedKeyEvent.Key.F1;
            break;

        case KeyboardEvent.Key.F2:
            result.key = RedKeyEvent.Key.F2;
            break;

        case KeyboardEvent.Key.F3:
            result.key = RedKeyEvent.Key.F3;
            break;

        case KeyboardEvent.Key.F4:
            result.key = RedKeyEvent.Key.F4;
            break;

        case KeyboardEvent.Key.F5:
            result.key = RedKeyEvent.Key.F5;
            break;

        case KeyboardEvent.Key.F6:
            result.key = RedKeyEvent.Key.F6;
            break;

        case KeyboardEvent.Key.F7:
            result.key = RedKeyEvent.Key.F7;
            break;

        case KeyboardEvent.Key.F8:
            result.key = RedKeyEvent.Key.F8;
            break;

        case KeyboardEvent.Key.F9:
            result.key = RedKeyEvent.Key.F9;
            break;

        case KeyboardEvent.Key.F10:
            result.key = RedKeyEvent.Key.F10;
            break;

        case KeyboardEvent.Key.F11:
            result.key = RedKeyEvent.Key.F11;
            break;

        case KeyboardEvent.Key.F12:
            result.key = RedKeyEvent.Key.F12;
            break;

        case KeyboardEvent.Key.LeftArrow:
            result.key = RedKeyEvent.Key.LEFT;
            break;

        case KeyboardEvent.Key.RightArrow:
            result.key = RedKeyEvent.Key.RIGHT;
            break;

        case KeyboardEvent.Key.UpArrow:
            result.key = RedKeyEvent.Key.UP;
            break;

        case KeyboardEvent.Key.DownArrow:
            result.key = RedKeyEvent.Key.DOWN;
            break;

        case KeyboardEvent.Key.Insert:
            result.key = RedKeyEvent.Key.INSERT;
            break;

        case KeyboardEvent.Key.Delete:
            result.key = RedKeyEvent.Key.DELETE;
            break;

        case KeyboardEvent.Key.Home:
            result.key = RedKeyEvent.Key.HOME;
            break;

        case KeyboardEvent.Key.End:
            result.key = RedKeyEvent.Key.END;
            break;

        case KeyboardEvent.Key.PageUp:
            result.key = RedKeyEvent.Key.PAGE_UP;
            break;

        case KeyboardEvent.Key.PageDown:
            result.key = RedKeyEvent.Key.PAGE_DOWN;
            break;

        case KeyboardEvent.Key.ScrollLock:
            result.key = RedKeyEvent.Key.SCROLL_LOCK;
            break;

        default:
            result.key = RedKeyEvent.Key.CHARACTER;
            result.character = event.which;
            break;
        }
    }
    else
    {
        result.key = RedKeyEvent.Key.CHARACTER;
        result.character = event.which;
    }

    return RedInputEvent(result);
}

private RedInputEvent convertMouseEvent(MouseEvent event)
{
    RedMouseEvent result;

    final switch (event.eventType)
    {
    case MouseEvent.Type.Moved:
        result.action = RedMouseEvent.Action.MOVED;
        break;

    case MouseEvent.Type.Pressed:
        result.action = RedMouseEvent.Action.PRESSED;
        break;

    case MouseEvent.Type.Released:
        result.action = RedMouseEvent.Action.RELEASED;
        break;

    case MouseEvent.Type.Clicked:
        result.action = RedMouseEvent.Action.CLICKED;
        break;
    }

    result.buttons = event.buttons;
    result.x = event.x;
    result.y = event.y;

    result.shift = (event.modifierState & ModifierState.shift) != 0;

    result.control = (event.modifierState & ModifierState.control) != 0;

    result.alt = (event.modifierState & ModifierState.alt) != 0;

    result.meta = (event.modifierState & ModifierState.meta) != 0;

    return RedInputEvent(result);
}

private RedInputEvent convertResizeEvent(SizeChangedEvent event)
{
    return RedInputEvent(RedResizeEvent(event.oldWidth, event.oldHeight,
            event.newWidth, event.newHeight));
}
