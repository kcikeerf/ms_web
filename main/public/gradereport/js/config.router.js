'use strict';

/**
 * Config for the router
 */
angular.module('app')
  .run(
    [          '$rootScope', '$state', '$stateParams',
      function ($rootScope,   $state,   $stateParams) {
          $rootScope.$state = $state;
          $rootScope.$stateParams = $stateParams;        
      }
    ]
  )
  .config(
    [          '$stateProvider', '$urlRouterProvider',
      function ($stateProvider,   $urlRouterProvider) {
          
          $urlRouterProvider
              .otherwise('/app/chart/diagnosis');
          $stateProvider
              .state('app', {
                  abstract: true,
                  url: '/app',
                  templateUrl: '/gradereport/tpl/app.html'
              })
              .state('app.chart', {
                  url: '/chart',
                  template: '<div ui-view class="fade-in-up"></div>'
              })
              .state('app.chart.diagnosis', {
                  url: '/diagnosis',
                  templateUrl: '/gradereport/tpl/ui_chart_diagnosis.html'
              })
              .state('app.chart.scale', {
                  url: '/scale',
                  templateUrl: '/gradereport/tpl/ui_chart_scale.html'
              })
              .state('app.chart.interval', {
                  url: '/interval',
                  templateUrl: '/gradereport/tpl/ui_chart_interval.html'
              })
              .state('app.chart.level1', {
                  url: '/level1',
                  templateUrl: '/gradereport/tpl/ui_chart_level1.html'
              })
              .state('app.chart.level2', {
                  url: '/level2',
                  templateUrl: '/gradereport/tpl/ui_chart_level2.html'
              })
              .state('app.chart.level3', {
                  url: '/level3',
                  templateUrl: '/gradereport/tpl/ui_chart_level3.html'
              })
              .state('app.chart.level4', {
                  url: '/level4',
                  templateUrl: '/gradereport/tpl/ui_chart_level4.html'
              })
              .state('app.chart.numscale1', {
                  url: '/numscalechart1',
                  templateUrl: '/gradereport/tpl/ui_chart_numscale1.html'
              })
              .state('app.chart.numscale2', {
                  url: '/numscalechart2',
                  templateUrl: '/gradereport/tpl/ui_chart_numscale2.html'
              })
              .state('app.chart.numscale3', {
                  url: '/numscalechart3',
                  templateUrl: '/gradereport/tpl/ui_chart_numscale3.html'
              })
              // table
              .state('app.table', {
                  url: '/table',
                  template: '<div ui-view class="fade-in-up"></div>'
              })
              .state('app.table.datatable1', {
                  url: '/datatable1',
                  templateUrl: '/gradereport/tpl/table_datatable1.html',
                  resolve: {
                      deps: ['$ocLazyLoad',
                          function( $ocLazyLoad ){
                              return $ocLazyLoad.load('ngGrid').then(
                                  function(){
                                      return $ocLazyLoad.load('/gradereport/js/controllers/grid_performance_knowledge.js');
                                  }
                              );
                          }]
                  }
              })
              .state('app.table.datatable2', {
                  url: '/datatable2',
                  templateUrl: '/gradereport/tpl/table_datatable2.html',
                  resolve: {
                      deps: ['$ocLazyLoad',
                          function( $ocLazyLoad ){
                              return $ocLazyLoad.load('ngGrid').then(
                                  function(){
                                      return $ocLazyLoad.load('/gradereport/js/controllers/grid_performance_skill.js');
                                  }
                              );
                          }]
                  }
              })
              .state('app.table.datatable3', {
                  url: '/datatable3',
                  templateUrl: '/gradereport/tpl/table_datatable3.html',
                  resolve: {
                      deps: ['$ocLazyLoad',
                          function( $ocLazyLoad ){
                              return $ocLazyLoad.load('ngGrid').then(
                                  function(){
                                      return $ocLazyLoad.load('/gradereport/js/controllers/grid_performance_capacity.js');
                                  }
                              );
                          }]
                  }
              })
              .state('app.numscale', {
                  url: '/numscale',
                  template: '<div ui-view class="fade-in-up"></div>'
              })
              .state('app.table.numscale1', {
                  url: '/numscale1',
                  templateUrl: '/gradereport/tpl/table_numscale1.html',
                  resolve: {
                      deps: ['$ocLazyLoad',
                          function( $ocLazyLoad ){
                              return $ocLazyLoad.load('ngGrid').then(
                                  function(){
                                      return $ocLazyLoad.load('/gradereport/js/controllers/grid_numscale_knowledge.js');
                                  }
                              );
                          }]
                  }
              })
              .state('app.table.numscale2', {
                  url: '/numscale2',
                  templateUrl: '/gradereport/tpl/table_numscale2.html',
                  resolve: {
                      deps: ['$ocLazyLoad',
                          function( $ocLazyLoad ){
                              return $ocLazyLoad.load('ngGrid').then(
                                  function(){
                                      return $ocLazyLoad.load('/gradereport/js/controllers/grid_numscale_skill.js');
                                  }
                              );
                          }]
                  }
              })
              .state('app.table.numscale3', {
                  url: '/numscale3',
                  templateUrl: '/gradereport/tpl/table_numscale3.html',
                  resolve: {
                      deps: ['$ocLazyLoad',
                          function( $ocLazyLoad ){
                              return $ocLazyLoad.load('ngGrid').then(
                                  function(){
                                      return $ocLazyLoad.load('/gradereport/js/controllers/grid_numscale_capacity.js');
                                  }
                              );
                          }]
                  }
              })
              .state('app.table.static', {
                  url: '/static',
                  templateUrl: '/gradereport/tpl/table_static.html',
                  resolve: {
                      deps: ['$ocLazyLoad',
                        function( $ocLazyLoad ){
                          return $ocLazyLoad.load('ngGrid').then(
                              function(){
                                  return $ocLazyLoad.load('/gradereport/js/controllers/grid.js');
                              }
                          );
                      }]
                  }
              })
              // pages
              .state('app.page', {
                  url: '/page',
                  template: '<div ui-view class="fade-in-down"></div>'
              })
              .state('app.docs1', {
                  url: '/unscramble1',
                  templateUrl: '/gradereport/tpl/unscramble1.html'
              })
              .state('app.docs2', {
                  url: '/unscramble2',
                  templateUrl: '/gradereport/tpl/unscramble2.html'
              })
              .state('app.docs3', {
                  url: '/unscramble3',
                  templateUrl: '/gradereport/tpl/unscramble3.html'
              })
      }
    ]
  );