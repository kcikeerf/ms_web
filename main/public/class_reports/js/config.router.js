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
                  templateUrl: '/class_reports/tpl/app.html'
              })
              .state('app.chart', {
                  url: '/chart',
                  template: '<div ui-view class="fade-in-up"></div>'
              })
              .state('app.chart.diagnosis', {
                  url: '/diagnosis',
                  templateUrl: '/class_reports/tpl/ui_chart_diagnosis.html'
              })
              .state('app.chart.scale', {
                  url: '/scale',
                  templateUrl: '/class_reports/tpl/ui_chart_scale.html'
              })
              // table
              .state('app.table', {
                  url: '/table',
                  template: '<div ui-view class="fade-in-up"></div>'
              })
              .state('app.table.KnowledgeDatatable', {
                  url: '/KnowledgeDatatable',
                  templateUrl: '/class_reports/tpl/table_datatable1.html'
              })
              .state('app.table.SkillDatatable', {
                  url: '/SkillDatatable',
                  templateUrl: '/class_reports/tpl/table_datatable2.html'
              })
              .state('app.table.CapacityDatatable', {
                  url: '/CapacityDatatable',
                  templateUrl: '/class_reports/tpl/table_datatable3.html'
              })
              .state('app.table.static', {
                  url: '/static',
                  templateUrl: '/class_reports/tpl/table_static.html',
                  resolve: {
                      deps: ['$ocLazyLoad',
                        function( $ocLazyLoad ){
                          return $ocLazyLoad.load('ngGrid').then(
                              function(){
                                  return $ocLazyLoad.load('/class_reports/js/controllers/grid.js');
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
                  templateUrl: '/class_reports/tpl/unscramble1.html'
              })
              .state('app.docs2', {
                  url: '/unscramble2',
                  templateUrl: '/class_reports/tpl/unscramble2.html'
              })
              .state('app.docs3', {
                  url: '/unscramble3',
                  templateUrl: '/class_reports/tpl/unscramble3.html'
              })
              .state('app.docs4', {
                  url: '/evaluate1',
                  templateUrl: '/class_reports/tpl/evaluate1.html'
              })
              .state('app.docs5', {
                  url: '/evaluate2',
                  templateUrl: '/class_reports/tpl/evaluate2.html'
              })
              .state('app.docs6', {
                  url: '/evaluate3',
                  templateUrl: '/class_reports/tpl/evaluate3.html'
              })
              .state('app.docs7', {
                  url: '/evaluate4',
                  templateUrl: '/class_reports/tpl/evaluate4.html'
              })
      }
    ]
  );
