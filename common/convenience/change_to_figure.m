function change_to_figure(h)
    try
        set(0,'CurrentFigure',h)
    catch
        figure(h);
    end
