% Clear the worckspace and console
clear;
clc;

eti('_air_conditioner');
eti('_car_horn');
eti('_children_playing');
eti('_dog_bark');
eti('_drilling');
eti('_engine_idling');
eti('_gun_shot');
eti('_jackhammer');
eti('_siren');
eti('_street_music');

disp('Done!');

function eti(class)

    f = waitbar(0, 'Initializing', 'Name', 'Progess status...', 'CreateCancelBtn', 'setappdata(gcbf,''canceling'',1)');

    % Set the necessary parameters
    sample_rate = 22050;
    texture_size = 128;
    texture_step = 64;
    metrics = {"mea", "std", "ske", "kur", "fla", "scr", "msd", "mcr"};
	files = {"mfccs", "p-sha", "p-spr", "s-dec", "s-fla", "s-flu", "s-rol", "s-sha", "s-slo", "s-var", "t-zcr"};
	
	w = 0;
    for k = 1 : 1 : size(files, 2)

        % Read input and prepare output
        file_name_in = strcat('E:\Desktop\PhD\Tools\Yaafe\esr\', class, '.wav.norm-', files{k},'.csv');
        data_in = csvread(file_name_in, 1, 0);
        length_in = size(data_in, 1);
        width_in = size(data_in, 2);
        length_out = int64((length_in - texture_size) / texture_step + 1);

        % Calculate features
        for j = 1 : 1 : width_in
		
            for i = 1 : 1 : length_out - 1
			
                % Input
                in = (i-1) * texture_step + 1;
                out = in + texture_size - 1;
                column = data_in(in:out, j);

                % MEA & VAR
                dist_parameters = fitdist(column, 'Normal');
                data_out(i, w+1:w+2) = dist_parameters.ParameterValues;
                data_out(i, w+1) = round(data_out(i, w+1), 8);
                data_out(i, w+2) = round(data_out(i, w+2), 8);

                % SKE
                data_out(i, w+3) = round(skewness(column), 8);
                
                % KUR
                data_out(i, w+4) = round(kurtosis(column), 8);

                % FLA
                data_out(i, w+5) = round(geomean(abs(column))/mean(column), 8);

                % CRF
                % data_out(i, w+6) = round(max(column)/mean(column), 8);

                % SCR
                scr = 0;
                for q = 1 : 1 : texture_size-2
                    if sign((column(q+2,1)-column(q+1,1))*(column(q+1,1)-column(q,1))) < 0
                        scr = scr + 1;
                    end
                end
                data_out(i, w+6) = round(scr/(texture_size-2), 8);

                % MSD
                msd = 0;
                for q = 1 : 1 : texture_size-1
                    msd = msd + abs(column(q+1,1)-column(q,1));
                end
                data_out(i, w+7) = round(msd/(texture_size-1), 8);

                % MCR
                mcr = 0;
                mea = mean(column);
                for q = 1 : 1 : texture_size-1
                    if sign((column(q+1,1)-mea)*(column(q,1)-mea)) < 0
                        mcr = mcr + 1;
                    end
                end
                data_out(i, w+8) = round(mcr/(texture_size-1), 8);
                
                % Progress
                % disp(['Processing: ', num2str(k), '/', num2str(size(files,2)), ' for ', class]);
                % disp(['Progress: ', num2str(k), '/', num2str(size(files,2)), ' | ' num2str(progress*100, '%.2f'), '%']);
                progress = double((i+1)+(j-1)*length_out) / double(length_out*width_in);
                waitbar(progress, f, sprintf(['Processing: ', num2str(k), '/', num2str(size(files,2)), ' for ', class]))
				if getappdata(f,'canceling')
                    return
                end
            end

            % Set column names
            for i = 1 : 1 : size(metrics, 2)
                labels_out(1, w+i) = cellstr(strcat(strrep(files{k}, "-", "_"), '_', num2str(j), '_', metrics{i}));
            end
            w = w + size(metrics, 2);
			
        end
        
    end

    % Write output
    data_out = array2table(data_out);
    data_out.Properties.VariableNames = labels_out;
    writetable(data_out, strcat('E:\Desktop\PhD\Tools\Yaafe\esr\', class, '.csv'))

end