function [projectRootDir, dataRootDir] = rootPath(useCluster, projectName)
% Return paths to the root tactile temporal normalization code and data directories
%
% This function must reside in the project directory structure.  
% It is used to determine the location of various sub-directories.
% 
% Toolbox dependencies: freesurfer,
%                       GLMdenoise (https://github.com/cvnlab/GLMdenoise), 
%                       jsonlab (https://github.com/NeuroJSON/jsonlab), 
%                       bads (https://github.com/acerbilab/bads),
%                       MRI_tools (https://github.com/WinawerLab/MRI_tools),
%                       ECoG_utils (https://github.com/WinawerLab/ECoG_utils)
%                       
% Example:
%   rootPath(false, 'tactileTemporalNormalization')

if ~exist('useCluster', 'var') || isempty(useCluster)
    useCluster = false;
end

if ~exist('projectName', 'var') || isempty(projectName)
   projectName = 'tactileTemporalNormalization'; 
end

toolboxDir      = [];

switch useCluster
    case true
        
        filePath        = fileparts(which('rootPath'));
        userName        = getenv('USER'); % find username. OSX: getenv('USER'), windows: getenv('USERNAME')
        
        projectRootDir  = fullfile(filePath);
        dataRootDir     = fullfile('/scratch', userName, ...
                            projectName, 'Data');
      
    case false
        
        % This is the path for the root folder 
        filePath        = fileparts(fileparts(which('rootPath')));
        projectRootDir  = fullfile(filePath);

        % or generate personalized path based on username:
        userName        = getenv('USER'); % find username. OSX: getenv('USER'), windows: getenv('USERNAME')

        switch userName

            % specify username
            case 'ibloem'
                
                % local location for Data folder
                dataRootDir     = fullfile('~', 'Documents', 'Experiments', projectName, 'Data');
    
                % toolboxes are stored in same git directory as project code
                toolboxDir  = fullfile(projectRootDir);

            otherwise
    
                % default location for Data folder
                dataRootDir     = fullfile(projectRootDir, 'Data');
                
                % toolboxes directory
                toolboxDir  = fullfile(projectRootDir, '..');
                
 
        end

end


%-- check if code dir is on path
p       = split(path, pathsep);
onPath = any(strcmpi(projectRootDir, p));
if ~onPath
    % add code to path
    addpath(genpath(projectRootDir));
    
    % add toolbox dependencies
    if exist(fullfile(toolboxDir, 'ECoG_utils'), "dir") > 0
        addpath(genpath(fullfile(toolboxDir, 'ECoG_utils')))
    else
        fprintf(2,'[rootPath] ECoG_utils toolbox not found on path.\n')
    end
    if exist(fullfile(toolboxDir, 'bads'), "dir") > 0
        addpath(genpath(fullfile(toolboxDir, 'bads')))
    else
        fprintf(2,'[rootPath] bads toolbox not found on path.\n')
    end
    if exist(fullfile(toolboxDir, 'GLMdenoise'), "dir") > 0
        addpath(genpath(fullfile(toolboxDir, 'GLMdenoise')))
    else
        fprintf(2,'[rootPath] GLMdenoise toolbox not found on path.\n')
    end
    if exist(fullfile(toolboxDir, 'jsonlab'), "dir") > 0
        addpath(genpath(fullfile(toolboxDir, 'jsonlab')))
    else
        fprintf(2,'[rootPath] jsonlab toolbox not found on path.\n')
    end
    if exist(fullfile(toolboxDir, 'MRI_tools'), "dir") > 0
        addpath(genpath(fullfile(toolboxDir, 'MRI_tools')))
    else
        fprintf(2,'[rootPath] MRI_tools toolbox not found on path.\n')
    end
    
    % check if freesurfer is on path: 
    freesurferDir = getenv('FREESURFER_HOME');
    if isempty(freesurferDir)
        fprintf(2,'[rootPath] FREESURFER_HOME not defined. Freesurfer was not added to path')
    else
        addpath(genpath(freesurferDir))
    end
end