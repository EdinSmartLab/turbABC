import logging
import os
import numpy as np
from time import time
from scipy.interpolate import RegularGridInterpolator

import pyabc.utils as utils
import pyabc.glob_var as g
import workfunc_rans


def sampling(sampling, C_limits, N):
    if sampling == 'random':
        array = utils.sampling_random(N, C_limits)
    elif sampling == 'uniform':
        array = utils.sampling_uniform_grid(N, C_limits)
    logging.info('Sampling is {}'.format(sampling))
    return array


def define_work_function():
    if g.case == 'impulsive':
        work_function = workfunc_rans.abc_work_function_impulsive
    elif g.case == 'periodic':
        work_function = workfunc_rans.abc_work_function_periodic
    elif g.case == 'decay':
        work_function = workfunc_rans.abc_work_function_decay
    elif g.case == 'strain_relax':
        work_function = workfunc_rans.abc_work_function_strain_relax
    else:
        logging.error('Unknown work function {}'.format(g.case))
    return work_function


def abc_classic(C_array):

    N_params = len(C_array[0])
    N = len(C_array)
    work_function = define_work_function()
    start = time()
    g.par_process.run(func=work_function, tasks=C_array)
    result = g.par_process.get_results()
    end = time()
    utils.timer(start, end, 'Time ')
    all_samples = np.array([C[:N_params] for C in result])
    dist = np.array([C[N_params:] for C in result])
    writing_size = 5e7
    if N > writing_size:
        n = int(N // writing_size)
        for i in range(n):
            np.savez(os.path.join(g.path['output'], 'classic_abc{}.npz'.format(i)),
                     C=all_samples[i*writing_size:(i+1)*writing_size], dist=dist[i*writing_size:(i+1)*writing_size])
        if N % writing_size != 0:
            np.savez(os.path.join(g.path['output'], 'classic_abc{}.npz'.format(n)),
                     C=all_samples[n * writing_size:], dist=dist[n * writing_size:])
    np.savez(os.path.join(g.path['output'], 'all_abc.npz'), C=all_samples, dist=dist)
    return


def mcmc_chains(C_init, adaptive=False):

    N_params = len(C_init[0])
    if adaptive:
        run_function = one_chain_adaptive
    else:
        run_function = one_chain
    start = time()
    g.par_process.run(func=run_function, tasks=C_init)
    result = g.par_process.get_results()
    end = time()
    accepted = np.array([chunk[:N_params] for item in result for chunk in item])
    dist = np.array([chunk[-1] for item in result for chunk in item])
    utils.timer(start, end, 'Time for running chains')
    np.savez(os.path.join(g.path['output'], 'accepted.npz'), C=accepted, dist=dist)
    logging.debug('Number of accepted parameters: {}'.format(len(accepted)))
    return accepted, dist


def calibration(algorithm_input, C_limits):

    N_params = len(C_limits)
    work_function = define_work_function()
    x = algorithm_input['x']
    logging.info('Sampling {}'.format(algorithm_input['sampling']))
    C_array = sampling(algorithm_input['sampling'], C_limits, algorithm_input['N_calibration'][0])
    logging.info('Calibration step 1 with {} samples'.format(len(C_array)))

    start_calibration = time()
    g.par_process.run(func=work_function, tasks=C_array)
    S_init = g.par_process.get_results()
    end_calibration = time()
    utils.timer(start_calibration, end_calibration, 'Time of calibration step 1')

    print('Number of inf = ', np.sum(np.isinf(np.array(S_init)[:, -1])))
    # Define epsilon
    logging.info('x = {}'.format(x[0]))
    S_init.sort(key=lambda y: y[-1])
    S_init = np.array(S_init)
    eps = np.percentile(S_init, q=int(x[0] * 100), axis=0)[-1]
    logging.info('eps after calibration step = {}'.format(eps))
    np.savetxt(os.path.join(g.path['calibration'], 'eps1'), [eps])
    np.savez(os.path.join(g.path['calibration'], 'calibration1.npz'), C=S_init[:, :-1], dist=S_init[:, -1])

    # Define new range
    g.C_limits = np.empty_like(C_limits)
    for i in range(N_params):
        max_S = np.max(S_init[:, i])
        min_S = np.min(S_init[:, i])
        if max_S - min_S < 1e-5:
            min_S -= g.std[i]
            max_S += g.std[i]
        half_length = algorithm_input['phi'] * (max_S - min_S) / 2.0
        middle = (max_S + min_S) / 2.0
        g.C_limits[i] = np.array([middle - half_length, middle + half_length])
    logging.info('New parameters range after calibration step:\n{}'.format(g.C_limits))
    np.savetxt(os.path.join(g.path['calibration'], 'C_limits'), g.C_limits)

    # Second calibration step
    logging.info('Sampling {}'.format(algorithm_input['sampling']))
    C_array = sampling(algorithm_input['sampling'], g.C_limits, algorithm_input['N_calibration'][1])
    logging.info('Calibration step 2 with {} samples'.format(len(C_array)))
    start_calibration = time()
    g.par_process.run(func=work_function, tasks=C_array)
    S_init = g.par_process.get_results()
    end_calibration = time()
    utils.timer(start_calibration, end_calibration, 'Time of calibration step 2')

    # Define epsilon again
    logging.info('x = {}'.format(x[1]))
    S_init.sort(key=lambda y: y[-1])
    S_init = np.array(S_init)
    g.eps = np.percentile(S_init, q=int(x[1] * 100), axis=0)[-1]
    logging.info('eps after calibration step = {}'.format(g.eps))
    np.savetxt(os.path.join(g.path['calibration'], 'eps2'), [g.eps])
    np.savez(os.path.join(g.path['calibration'], 'calibration2.npz'), C=S_init[:, :-1], dist=S_init[:, -1])

    # Define std
    S_init = S_init[np.where(S_init[:, -1] < g.eps)]
    g.std = algorithm_input['phi']*np.std(S_init[:, :-1], axis=0)
    logging.info('std for each parameter after calibration step:{}'.format(g.std))
    np.savetxt(os.path.join(g.path['calibration'], 'std'), [g.std])
    for i, std in enumerate(g.std):
        if std < 1e-8:
            g.std += 1e-5
            logging.warning('Artificially added std! Consider increasing number of samples for calibration step')
            logging.warning('new std for each parameter after calibration step:{}'.format(g.std))

    # update prior based on accepted parameters in calibration
    if algorithm_input['prior_update']:
        prior, C_calibration = utils.gaussian_kde_scipy(data=S_init[:, :-1],
                                                        a=g.C_limits[:, 0],
                                                        b=g.C_limits[:, 1],
                                                        num_bin_joint=algorithm_input['prior_update'])
        logging.info('Estimated parameter after calibration step is {}'.format(C_calibration))
        np.savez(os.path.join(g.path['calibration'], 'prior.npz'), Z=prior)
        np.savetxt(os.path.join(g.path['calibration'], 'C_final_smooth'), C_calibration)
        prior_grid = np.empty((N_params, algorithm_input['prior_update']+1))
        for i, limits in enumerate(g.C_limits):
            prior_grid[i] = np.linspace(limits[0], limits[1], algorithm_input['prior_update']+1)
        g.prior_interpolator = RegularGridInterpolator(prior_grid, prior, bounds_error=False)

    # Randomly choose starting points for Markov chains
    C_start = (S_init[np.random.choice(S_init.shape[0], g.par_process.proc, replace=False), :-1])
    np.set_printoptions(precision=3)
    logging.info('starting parameters for MCMC chains:\n{}'.format(C_start))
    C_array = C_start.tolist()
    return C_array


def one_chain(C_init):
    N = g.N_per_chain
    C_limits = g.C_limits
    N_params = len(C_init)
    work_function = define_work_function()
    result = np.empty((N, N_params + 1), dtype=np.float32)
    s_d = 2.4 ** 2 / N_params  # correct covariance according to dimensionality

    # add first param
    result[0, :] = work_function(C_init)
    ####################################################################################################################
    def mcmc_step_burn_in(i):
        nonlocal counter_sample, counter_dist
        while True:
            while True:
                counter_sample += 1
                c = np.random.normal(result[i - 1, :-1], g.std)
                if not (False in (C_limits[:, 0] < c) * (c < C_limits[:, 1])):
                    break
            distance = work_function(c)
            counter_dist += 1
            if distance[-1] <= g.eps:
                result[i, :] = distance
                break
        return

    def mcmc_step(i):
        nonlocal mean_prev, cov_prev, counter_sample, counter_dist
        while True:
            while True:
                counter_sample += 1
                c = np.random.multivariate_normal(result[i - 1, :-1], cov=s_d*cov_prev)
                if not (False in (C_limits[:, 0] < c) * (c < C_limits[:, 1])):
                    break
            distance = work_function(c)
            counter_dist += 1
            if distance[-1] <= g.eps:
                result[i, :] = distance
                break
        cov_prev, mean_prev = utils.covariance_recursive(result[i, :-1], i, cov_prev, mean_prev)
        return

    def mcmc_step_burn_in_prior(i):
        nonlocal counter_sample, counter_dist
        while True:
            while True:
                counter_sample += 1
                c = np.random.normal(result[i - 1, :-1], g.std)
                if not (False in (C_limits[:, 0] < c) * (c < C_limits[:, 1])):
                    break
            distance = work_function(c)
            counter_dist += 1
            if distance[-1] <= g.eps:
                prior_values = g.prior_interpolator([result[i - 1, :-1], c])
                if np.random.random() < prior_values[0]/prior_values[1]:
                    result[i, :] = distance
                    break
        return

    def mcmc_step_prior(i):
        nonlocal mean_prev, cov_prev, counter_sample, counter_dist
        while True:
            while True:
                counter_sample += 1
                c = np.random.multivariate_normal(result[i - 1, :-1], cov=s_d*cov_prev)
                if not (False in (C_limits[:, 0] < c) * (c < C_limits[:, 1])):
                    break
            distance = work_function(c)
            counter_dist += 1
            if distance[-1] <= g.eps:
                prior_values = g.prior_interpolator([result[i - 1, :-1], c])
                if np.random.random() < prior_values[0] / prior_values[1]:
                    result[i, :] = distance
                    break
        cov_prev, mean_prev = utils.covariance_recursive(result[i, :-1], i, cov_prev, mean_prev)
        return
    #######################################################
    # Markov Chain
    counter_sample = 0
    counter_dist = 0
    mean_prev = 0
    cov_prev = 0
    # if changed prior after calibration step
    if g.prior_interpolator is None:
        mcmc_step_burn_in = mcmc_step_burn_in
        mcmc_step = mcmc_step
    else:
        mcmc_step_burn_in = mcmc_step_burn_in_prior
        mcmc_step = mcmc_step_prior

    # burn in period with constant variance
    for i in range(1, min(g.t0, N)):
        mcmc_step_burn_in(i)
    # define mean and covariance from burn-in period
    mean_prev = np.mean(result[:g.t0, :-1], axis=0)
    cov_prev = s_d * np.cov(result[:g.t0, :-1].T)
    # start period with adaptation
    for i in range(g.t0, N):
        mcmc_step(i)
        if i % int(N/100) == 0:
            logging.info("Accepted {} samples".format(i))
    #######################################################
    print('Number of model and distance evaluations: {} ({} accepted)'.format(counter_dist, N))
    print('Number of sampling: {} ({} accepted)'.format(counter_sample, N))
    logging.info('Number of model and distance evaluations: {} ({} accepted)'.format(counter_dist, N))
    logging.info('Number of sampling: {} ({} accepted)'.format(counter_sample, N))
    return result.tolist()


def one_chain_adaptive(C_init):
    N = g.N_per_chain
    C_limits = g.C_limits
    N_params = len(C_init)
    target_acceptance = g.target_acceptance
    work_function = define_work_function()
    result = np.empty((N, N_params + 1), dtype=np.float32)
    s_d = 2.38 ** 2 / N_params  # correct covariance according to dimensionality

    # add first param
    result[0, :] = work_function(C_init)
    delta = result[0, -1]
    std = np.sqrt(0.1*(C_limits[:, 1] - C_limits[:, 0]))

    ####################################################################################################################
    def mcmc_step_burn_in_adaptive(i):
        nonlocal counter_sample, counter_dist, delta, std, target_acceptance
        while True:
            while True:
                counter_sample += 1
                c = np.random.normal(result[i - 1, :-1], std)
                if not (False in (C_limits[:, 0] < c) * (c < C_limits[:, 1])):
                    break
            distance = work_function(c)
            counter_dist += 1
            if distance[-1] <= delta:
                result[i, :] = distance
                delta *= np.exp((i + 1) ** (-2 / 3) * (target_acceptance - 1))
                break
            else:
                delta *= np.exp((i + 1) ** (-2 / 3) * target_acceptance)
        return

    def mcmc_step_adaptive(i):
        nonlocal mean_prev, cov_prev, counter_sample, counter_dist, delta
        while True:
            while True:
                counter_sample += 1
                c = np.random.multivariate_normal(result[i - 1, :-1], cov=s_d*cov_prev)
                if not (False in (C_limits[:, 0] < c) * (c < C_limits[:, 1])):
                    break
            distance = work_function(c)
            counter_dist += 1
            if distance[-1] <= delta:
                result[i, :] = distance
                delta *= np.exp((i+1)**(-2/3)*(target_acceptance-1))
                break
            else:
                delta *= np.exp((i+1) ** (-2 / 3) * target_acceptance)
        cov_prev, mean_prev = utils.covariance_recursive(result[i, :-1], i, cov_prev, mean_prev)
        return
    #######################################################
    # Markov Chain
    counter_sample = 0
    counter_dist = 0
    mean_prev, cov_prev = 0, 0
    # burn in period with constant variance
    for i in range(1, min(g.t0, N)):
        mcmc_step_burn_in_adaptive(i)
    # define mean and covariance from burn-in period
    mean_prev = np.mean(result[:g.t0, :-1], axis=0)
    cov_prev = s_d * np.cov(result[:g.t0, :-1].T)
    # start period with adaptation
    for i in range(g.t0, N):
        mcmc_step_adaptive(i)
        if i % (int(N // 1000)+1) == 0:
            logging.info("Accepted {} samples".format(i))
    #######################################################
    print('Number of model and distance evaluations: {} ({} accepted)'.format(counter_dist, N))
    print('Number of sampling: {} ({} accepted)'.format(counter_sample, N))
    logging.info('Number of model and distance evaluations: {} ({} accepted)'.format(counter_dist, N))
    logging.info('Number of sampling: {} ({} accepted)'.format(counter_sample, N))
    return result.tolist()
