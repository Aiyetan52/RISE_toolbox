function [p,R,W,B]=gelman_rubin(obj,recursive)

if nargin<2
    
    recursive=false;
    
end

m=obj.nchains;

if recursive
    
    last=2;
    
else
    
    last=obj.npop;
    
end

niter=obj.npop-last+1;

% for istart=last:obj.npop
time_end=obj.start;

for iter=1:niter
    
    time_end=time_end+1;
    
    [Ri,Wi,Bi,Vi]=do_one_recursion(obj.draws(:,1:last+iter-1));
    
    if iter==1
        
        R=Ri(:,ones(niter,1));
        
        W=Wi(:,ones(niter,1));
        
        B=Bi(:,ones(niter,1));
        
        V=Vi(:,ones(niter,1));
        
    end
    
    R(:,iter)=Ri;
    
    W(:,iter)=Wi;
    
    B(:,iter)=Bi;
    
    V(:,iter)=Vi;
    
end

p=struct();

for iname=1:obj.nparams
    
    p.(obj.pnames{iname})=struct('within_variance',W(iname,:),...
        'between_variance',B(iname,:),'variance',V(iname,:),'psrf',R(iname,:),...
        'time',obj.start+1:time_end);
    
end


    function [R,W,B,Vthet]=do_one_recursion(these_draws)
        
        two_n=size(these_draws,2);
        
%         if obj.i_dropped>0
%             % do not drop more than necessary
%             n=two_n;
%             
%         else
            
            n=floor(0.5*two_n);
            
%         end
        
        % 2. Discard half of the draws
        %-----------------------------
        newDraws=load_draws();
        
        % 3. Calculate the within-chain and between-chain variances
        %----------------------------------------------------------
        W=within_chain_variance();
        
        B=between_chain_variance();
        
        % 4. calculate the estimated variance of the parameter as a weighted sum of
        % the within-chain and between-chain variances
        Vthet=(1-1/n)*W+1/n*B;
        
        % 5. Calculate the potential scale reduction factor
        %------------------------------ --------------------
        R=sqrt(Vthet./W);
        
        function [w,s2j]=within_chain_variance()
            
            s2j=zeros(obj.nparams,m);
            
            for ichain=1:m
                
                s2j(:,ichain)=var(newDraws{ichain},1,2);
                
            end
            
            w=mean(s2j,2);
            
        end
        
        function b=between_chain_variance()
            
            theta_bar=zeros(obj.nparams,m);
            
            for ichain=1:m
                
                theta_bar(:,ichain)=mean(newDraws{ichain},2);
                
            end
            
            theta_bar_bar=mean(theta_bar,2);
            
            b=n/(m-1)*sum(bsxfun(@minus,theta_bar,theta_bar_bar).^2,2);
            
        end
        
        function newDraws=load_draws()
            
            newDraws=these_draws(:,end-n+1:end);
            
            tmp=cell(m,1);
            
            for ichain=1:m
                
                tmp{ichain}=[newDraws(ichain,:).x];
                
            end
            
            newDraws=tmp;
            
        end
        
    end

end
