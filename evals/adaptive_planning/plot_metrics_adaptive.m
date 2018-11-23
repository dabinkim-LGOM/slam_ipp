function [] = plot_metrics_adaptive(metrics)
% Plots logged informative metrics.

do_plot = 1;

text_size = 10.5;

time_vector = 0:0.1:200;

times = metrics.times;
P_traces = metrics.P_traces;
P_traces_interesting = metrics.P_traces_interesting;
rmses = metrics.rmses;
rmses_interesting = metrics.rmses_interesting;

ts = timeseries(P_traces, times);
ts_resampled = resample(ts, time_vector, 'zoh');
P_traces_resampled = ts_resampled.data';

ts = timeseries(P_traces_interesting, times);
ts_resampled = resample(ts, time_vector, 'zoh');
P_traces_interesting_resampled = ts_resampled.data';

ts = timeseries(rmses, times);
ts_resampled = resample(ts, time_vector, 'zoh');
rmses_resampled = ts_resampled.data';

ts = timeseries(rmses_interesting, times);
ts_resampled = resample(ts, time_vector, 'zoh');
rmses_interesting_resampled = ts_resampled.data';

if (do_plot)

    % GP field covariance trace
    subplot(2,3,1)
    hold on
    set(gca, ...
        'Box'         , 'off'     , ...
        'TickDir'     , 'out'     , ...
        'TickLength'  , [.02 .02] , ...
        'XMinorTick'  , 'on'      , ...
        'YMinorTick'  , 'off'      , ...
        'YTickMode'   , 'auto'  , ...
        'YGrid'       , 'on'      , ...
        'XColor'      , [.3 .3 .3], ...
        'YColor'      , [.3 .3 .3], ...
        'YScale'      , 'log'     , ...
        'YGrid'       , 'on'      , ...
        'LineWidth'   , 1         , ...
        'FontSize'    , text_size , ...
        'LooseInset'  , max(get(gca,'TightInset'), 0.02));
    
    plot(time_vector, P_traces_resampled)
    axis([0 time_vector(end) 0 6*10^7])
    h_xlabel = xlabel('Time (s)');
    h_ylabel = ylabel('GP cov. trace');
    set([h_xlabel, h_ylabel], ...
        'FontName'   , 'Helvetica');
    hold off
    
    % GP field covariance trace - interesting areas.
    subplot(2,3,2)
    hold on
    set(gca, ...
        'Box'         , 'off'     , ...
        'TickDir'     , 'out'     , ...
        'TickLength'  , [.02 .02] , ...
        'XMinorTick'  , 'on'      , ...
        'YMinorTick'  , 'off'      , ...
        'YTickMode'   , 'auto'  , ...
        'YGrid'       , 'on'      , ...
        'XColor'      , [.3 .3 .3], ...
        'YColor'      , [.3 .3 .3], ...
        'YScale'      , 'log'     , ...
        'YGrid'       , 'on'      , ...
        'LineWidth'   , 1         , ...
        'FontSize'    , text_size , ...
        'LooseInset'  , max(get(gca,'TightInset'), 0.02));
    
    plot(time_vector, P_traces_interesting_resampled)
    axis([0 time_vector(end) 0 6*10^7])
    h_xlabel = xlabel('Time (s)');
    h_ylabel = ylabel('GP cov. trace - interesting');
    set([h_xlabel, h_ylabel], ...
        'FontName'   , 'Helvetica');
    hold off
    
    % RMSE
    subplot(2,3,4)
    hold on
    set(gca, ...
        'Box'         , 'off'     , ...
        'TickDir'     , 'out'     , ...
        'TickLength'  , [.02 .02] , ...
        'XMinorTick'  , 'on'      , ...
        'YMinorTick'  , 'on'      , ...
        'YGrid'       , 'on'      , ...
        'XColor'      , [.3 .3 .3], ...
        'YColor'      , [.3 .3 .3], ...
        'YTick'       , 0:1:8, ...
        'LineWidth'   , 1         , ...
        'FontSize'    , text_size, ...
        'LooseInset', max(get(gca,'TightInset'), 0.02));
    
    plot(time_vector, rmses_resampled)
    axis([0 time_vector(end) 1 8.5])
    h_xlabel = xlabel('Time (s)');
    h_ylabel = ylabel('RMSE');
    set([h_xlabel, h_ylabel], ...
        'FontName'   , 'Helvetica');
    hold off
    
    % RMSE - interesting areas
    subplot(2,3,5)
    hold on
    set(gca, ...
        'Box'         , 'off'     , ...
        'TickDir'     , 'out'     , ...
        'TickLength'  , [.02 .02] , ...
        'XMinorTick'  , 'on'      , ...
        'YMinorTick'  , 'on'      , ...
        'YGrid'       , 'on'      , ...
        'XColor'      , [.3 .3 .3], ...
        'YColor'      , [.3 .3 .3], ...
        'YTick'       , 0:1:8, ...
        'LineWidth'   , 1         , ...
        'FontSize'    , text_size, ...
        'LooseInset', max(get(gca,'TightInset'), 0.02));
    
    plot(time_vector, rmses_interesting_resampled)
    axis([0 time_vector(end) 1 8.5])
    h_xlabel = xlabel('Time (s)');
    h_ylabel = ylabel('RMSE');
    set([h_xlabel, h_ylabel], ...
        'FontName'   , 'Helvetica');
    hold off
    
    set(gcf, 'Position', [345, 146, 1208, 707]);
    
end

end