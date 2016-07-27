'use strict';

/**
 * Config for the router
 */
angular.module('app')
  .run(
    [ '$rootScope', '$state', '$stateParams',
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
                  templateUrl: '/pupilreport/tpl/app.html'
              })
              .state('app.chart', {
                  url: '/chart',
                  template: '<div ui-view class="fade-in-up"></div>'
              })
              .state('app.chart.diagnosis', {
                  url: '/diagnosis',
                  templateUrl: '/pupilreport/tpl/ui_chart_diagnosis.html'
              })
              // table
              .state('app.table', {
                  url: '/table',
                  template: '<div ui-view class="fade-in-up"></div>'
              })
              .state('app.table.knowledge', {
                  url: '/knowledge',
                  templateUrl: '/pupilreport/tpl/table_datatable1.html'
              })
              .state('app.table.skill', {
                  url: '/skill',
                  templateUrl: '/pupilreport/tpl/table_datatable2.html'
              })
              .state('app.table.capacity', {
                  url: '/capacity',
                  templateUrl: '/pupilreport/tpl/table_datatable3.html'
              })
              // pages
              .state('app.page', {
                  url: '/page',
                  template: '<div ui-view class="fade-in-down"></div>'
              })
              .state('app.docs', {
                  url: '/docs',
                  templateUrl: '/pupilreport/tpl/unscramble.html'
              })
      }
    ]
  );