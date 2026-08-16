module tui.renderer;

import arsd.terminal;

private struct Cell
{
    dchar c;
}

private struct Buffer
{
    Cell[] cells;
    int width;
    int height;
    bool initialized = false;

    void resize(int width, int height)
    {
        if (this.width == width && this.height == height)
        {
            return;
        }

        this.width = width;
        this.height = height;
        this.cells.length = width * height;
    }

    ref Cell at(int x, int y)
    {
        return this.cells[y * this.width + x];
    }

    void clear(dchar c = ' ')
    {
        foreach (ref cell; this.cells)
        {
            cell.c = c;
        }
    }
}

public class Renderer
{
    private Terminal* terminal;
    private Buffer frontBuffer;
    private Buffer backBuffer;

    this(Terminal* terminal)
    {
        this.terminal = terminal;
        this.frontBuffer.resize(this.terminal.width, this.terminal.height);
        this.backBuffer.resize(this.terminal.width, this.terminal.height);
        this.frontBuffer.clear();
        this.backBuffer.clear();
    }

    public void beginFrame()
    {
        this.backBuffer.clear();
    }

    private void drawAt(int x, int y, dchar c)
    {
        if (x < 0 || x >= this.backBuffer.width || y < 0 || y >= this.backBuffer.height)
        {
            return;
        }

        this.backBuffer.at(x, y).c = c;
    }

    public void flush()
    {
        for (int y = 0; y < this.backBuffer.height; y++)
        {
            for (int x = 0; x < this.backBuffer.width; x++)
            {
                auto i = y * this.backBuffer.width + x;

                if (this.backBuffer.cells[i].c == this.frontBuffer.cells[i].c)
                {
                    continue;
                }

                this.terminal.moveTo(x, y);
                this.terminal.write(this.backBuffer.cells[i].c);

                this.frontBuffer.cells[i] = this.backBuffer.cells[i];
            }
        }

        this.terminal.flush();
    }

    public void box(int x, int y, int width, int height)
    {

        for (int i = 1; i < width - 1; i++)
        {
            this.drawAt(x + i, y, '─');
        }

        for (int i = 1; i < width - 1; i++)
        {
            this.drawAt(x + i, y + height - 1, '─');
        }

        for (int i = 1; i < height - 1; i++)
        {
            this.drawAt(x, y + i, '│');
        }

        for (int i = 1; i < height - 1; i++)
        {
            this.drawAt(x + width - 1, y + i, '│');
        }

        this.drawAt(x, y, '┌');
        this.drawAt(x + width - 1, y, '┐');
        this.drawAt(x, y + height - 1, '└');
        this.drawAt(x + width - 1, y + height - 1, '┘');
    }
}
